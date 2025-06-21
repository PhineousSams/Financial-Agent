defmodule FinincialAgent.Workers.Helpers.ZraEncoder do
  require Logger

  @prov_id "NTSV"

  def encrypt_data(%{service: service, req: request_data} = params) when is_map(params) do

    with {:ok, business_data} <- Jason.encode(request_data),
         {:ok, encrypted} <- encrypt_string(business_data),
         signature <- get_in(encrypted, [:key, :signature]),
         key <- get_in(encrypted, [:key, :key]),
         body <- get_in(encrypted, [:key, :body]),
         message_id <- message_id() do

      # Format the final request message
      final_request_message = %{
        header: %{
          serviceName: service,
          providerCode: @prov_id,
          messageId: message_id,
          signature: signature,
          key: key
        },
        body: body
      }

      Logger.debug(fn -> "Request: #{inspect(final_request_message, pretty: true)}" end)

      # Send the request
      case Jason.encode(final_request_message) do
        {:ok, json_request} -> {:ok, json_request}

        {:error, reason} ->
          Logger.error("Failed to encode request: #{inspect(reason)}")
          {:error, :request_encoding_failed}
      end
    else
      {:error, reason} ->
        Logger.error("Encryption failed: #{inspect(reason)}")
        {:error, :encryption_failed}
    end
  end

  @doc """
  Generate a unique message ID for API requests.
  Format: "<provider_code>" + YYYYMMDDHHMMSS + 3 random bytes as hex
  """
  @spec message_id() :: String.t()
  def message_id do
    timestamp =
      DateTime.utc_now()
      |> Calendar.strftime("%Y%m%d%H%M%S")

    random_bytes = :crypto.strong_rand_bytes(3)
    |> Base.encode16(case: :lower)

    @prov_id <> timestamp <> random_bytes
  end

  @doc """
  Encrypt business data for sending to ZRA.

  ## Parameters
    - data: Map containing the business data to encrypt

  ## Returns
    - {:ok, encrypted_data} or {:error, reason}
  """
  @spec encrypt(map()) :: {:ok, map()} | {:error, term()}
  def encrypt(data) when is_map(data) do
    # Convert map to JSON string
    case Jason.encode(data) do
      {:ok, body} -> encrypt_string(body)
      {:error, reason} -> {:error, :json_encode_failed}
    end
  end

  @doc """
  Encrypt business data string for sending to ZRA.

  ## Parameters
    - body: String containing the business data to encrypt (typically JSON)

  ## Returns
    - {:ok, encrypted_data} or {:error, reason}
  """
  @spec encrypt(binary()) :: {:ok, map()} | {:error, term()}
  def encrypt(body) when is_binary(body) do
    encrypt_string(body)
  end

  # Private function to handle the actual encryption
  @spec encrypt_string(binary()) :: {:ok, map()} | {:error, term()}
  defp encrypt_string(body) do
    with {:ok, {_my_public_key, my_private_key}} <- init_keys(),
         [entry] <- :public_key.pem_decode(my_private_key),
         private_key <- :public_key.pem_entry_decode(entry) do

      try do
        # 1. Sign the business data
        signature = :public_key.sign(body, :sha256, private_key)

        # 2. Encrypt the business data
        # 2.1 Generate IV
        iv = :crypto.strong_rand_bytes(16)

        # 2.2 Generate random secret key
        secret_key = :crypto.strong_rand_bytes(32)

        # 2.3 Encrypt business data
        # Apply PKCS7 padding to match Node.js cipher.final() behavior
        padded_data = pkcs7_pad(body, 16)
        encrypted = :crypto.crypto_one_time(:aes_256_cbc, secret_key, iv, padded_data, true)

        # 2.4 Combine IV and encrypted data
        encrypted_iv_and_text = iv <> encrypted

        # Extract the public key from the certificate
        with {:ok, public_key} <- get_public_key() do
          # Encrypt the secret key using RSA with PKCS1 padding
          encrypted_secret_key = :public_key.encrypt_public(secret_key, public_key, [{:rsa_padding, :rsa_pkcs1_padding}])

          # 4. Create the final message - Match Node.js structure
          {:ok, %{
            key: %{
              signature: Base.encode64(signature),
              key: Base.encode64(encrypted_secret_key),
              body: Base.encode64(encrypted_iv_and_text)
            }
          }}
        else
          {:error, reason} ->
            Logger.error("Failed to get ZRA public key: #{inspect(reason)}")
            {:error, reason}
        end
      rescue
        e ->
          Logger.error("Encryption error: #{inspect(e)}")
          {:error, :encryption_failed}
      end
    else
      {:error, reason} ->
        {:error, reason}
      [] ->
        Logger.error("No private key entries found in PEM file")
        {:error, :no_private_key_entries}
      error ->
        Logger.error("Unexpected error in encryption: #{inspect(error)}")
        {:error, :encryption_failed}
    end
  end

  # PKCS7 padding function to match Node.js cipher.final() behavior
  defp pkcs7_pad(data, block_size) do
    padding_size = block_size - rem(byte_size(data), block_size)
    data <> :binary.copy(<<padding_size>>, padding_size)
  end

  @doc """
  Decrypt response data from ZRA.

  ## Parameters
    - response_json: String containing the encrypted response from ZRA

  ## Returns
    - {:ok, decrypted_response} or {:error, reason}
  """
  @spec decrypt(binary()) :: {:ok, binary()} | {:error, term()}
  def decrypt(response_json) do
    # Get private key
    with {:ok, {_, my_private_key}} <- init_keys() do
      try do
        # Parse response
        case Jason.decode(response_json) do
          {:ok, response} ->
            # Extract key and body
            key = get_in(response, ["header", "key"])
            body = get_in(response, ["body"])

            if is_nil(key) || is_nil(body) do
              # If no encryption was used, just return the response details
              final_response_message = %{
                serviceName: get_in(response, ["header", "ServiceName"]),
                statusCode: get_in(response, ["header", "statusCode"]),
                statusDescription: get_in(response, ["header", "statusDescription"])
              }

              Logger.debug("Response was not encrypted. Status: #{get_in(response, ["header", "statusCode"])}")
              {:ok, final_response_message}
            else
              # Parse the PEM-encoded private key
              with [entry] <- :public_key.pem_decode(my_private_key),
                   private_key <- :public_key.pem_entry_decode(entry) do

                # Decrypt the secret key
                encrypted_secret_key = Base.decode64!(key)
                case :public_key.decrypt_private(
                  encrypted_secret_key,
                  private_key,
                  [{:rsa_padding, :rsa_pkcs1_padding}]
                ) do
                  :error ->
                    Logger.error("Failed to decrypt secret key")
                    {:error, :secret_key_decryption_failed}

                  decrypted_secret_key ->
                    # Decrypt the business data
                    encrypted_iv_and_text = Base.decode64!(body)

                    case encrypted_iv_and_text do
                      <<iv::binary-size(16), encrypted_business_data::binary>> ->
                        decrypted_business_data = :crypto.crypto_one_time(
                          :aes_256_cbc,
                          decrypted_secret_key,
                          iv,
                          encrypted_business_data,
                          false
                        )

                        # Remove PKCS7 padding
                        unpadded_data = pkcs7_unpad(decrypted_business_data)
                        Logger.debug("Successfully decrypted response")

                        # Return the decrypted data
                        {:ok, Poison.decode!(unpadded_data)}

                      _ ->
                        Logger.error("Invalid encrypted data format")
                        {:error, :invalid_encrypted_data}
                    end
                end
              else
                [] ->
                  Logger.error("No private key entries found in PEM file")
                  {:error, :no_private_key_entries}
                error ->
                  Logger.error("Unexpected error in decryption: #{inspect(error)}")
                  {:error, :decryption_failed}
              end
            end

          {:error, reason} ->
            Logger.error("Failed to parse response JSON: #{inspect(reason)}")
            {:error, :invalid_response_json}
        end
      rescue
        e ->
          Logger.error("Error decrypting response: #{inspect(e)}")
          {:error, :decryption_failed}
      end
    else
      {:error, reason} -> {:error, reason}
    end
  end

  # PKCS7 unpadding function to match Node.js decipher.final() behavior
  defp pkcs7_unpad(data) do
    padding_size = :binary.last(data)
    binary_part(data, 0, byte_size(data) - padding_size)
  end



  @doc """
  Initialize the cryptographic keys.

  Returns {:ok, {public_key, private_key}} or {:error, reason}
  """
  @spec init_keys() :: {:ok, {binary(), binary()}} | {:error, term()}
  def init_keys do
    # Load configuration
    priv_dir = :code.priv_dir(:financial_agent)
    certs_dir = Path.join(priv_dir, "certs")

    certificate_path = Application.get_env(:financial_agent, :certificate_path, Path.join(certs_dir, "natsave.crt"))
    private_key_path = Application.get_env(:financial_agent, :private_key_path, Path.join(certs_dir, "natsave.key"))

    # Load my public and private keys
    with {:ok, my_public_key} <- File.read(certificate_path),
         {:ok, my_private_key} <- File.read(private_key_path) do
      {:ok, {my_public_key, my_private_key}}
    else
      {:error, reason} ->
        Logger.error("Failed to read keys: #{inspect(reason)}")
        {:error, reason}
    end
  end



  @doc """
  Extract the public key from ZRA's certificate.

  Returns {:ok, public_key} or {:error, reason}
  """
  @spec get_public_key() :: {:ok, :public_key.rsa_public_key()} | {:error, term()}
  def get_public_key do
    priv_dir = :code.priv_dir(:financial_agent)
    certs_dir = Path.join(priv_dir, "certs")
    zra_cert = Application.get_env(:financial_agent, :zra_cert_path, Path.join(certs_dir, "zra.org.zm.crt"))

    with {:ok, zra_public_key} <- File.read(zra_cert),
         [entry] <- :public_key.pem_decode(zra_public_key),
         cert <- :public_key.pem_entry_decode(entry) do

      # Extract the public key from the certificate
      case cert do
        {:Certificate, cert_data, _, _} ->
          # Find the SubjectPublicKeyInfo in the TBSCertificate
          subject_public_key_info =
            case cert_data do
              # Match the exact structure for the certificate
              {:TBSCertificate, _, _, _, _, _, _, {:SubjectPublicKeyInfo, _, _} = spki, _, _, _} ->
                {:ok, spki}
              # Direct access to the 7th element (index 6) if pattern matching fails
              {:TBSCertificate, _, _, _, _, _, _, spki, _, _, _} when is_tuple(spki) ->
                {:ok, spki}
              # Fallback for other structures
              _other ->
                {:error, :unable_to_extract_subject_public_key_info}
            end

          with {:ok, spki} <- subject_public_key_info,
               {:SubjectPublicKeyInfo, _, key_bin} <- spki,
               {:RSAPublicKey, modulus, exponent} <- :public_key.der_decode(:RSAPublicKey, key_bin) do
            {:ok, {:RSAPublicKey, modulus, exponent}}
          else
            {:error, reason} -> {:error, reason}
            _other -> {:error, :invalid_key_format}
          end

        other ->
          # If it's already a public key, use it directly
          if match?({:RSAPublicKey, _, _}, other) do
            {:ok, other}
          else
            {:error, :invalid_certificate_format}
          end
      end
    else
      {:error, reason} ->
        Logger.error("Failed to read ZRA certificate: #{inspect(reason)}")
        {:error, reason}
      [] ->
        Logger.error("No certificate entries found in PEM file")
        {:error, :no_certificate_entries}
      error ->
        Logger.error("Unexpected error processing certificate: #{inspect(error)}")
        {:error, :certificate_processing_error}
    end
  end
end
