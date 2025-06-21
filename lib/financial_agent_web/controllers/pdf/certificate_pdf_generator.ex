defmodule CertificatePdfGenerator do
  use FinincialToolWeb, :controller
  import Plug.Conn

  @green "#2ecc71"
  @amber "#f39c12"
  @foreground "#333333"


  def generate_pdf(applicant) do
    html =
      Sneeze.render([
        :html,
        [
          :body,
          %{
            style:
              style(%{
                "font-family" => "Helvetica, Arial, sans-serif",
                "font-size" => "20pt",
                "color" => @foreground,
                "background-color" => "#f9f9f9",
                "margin" => "0",
                "padding" => "40pt"
              })
          },
          render_header(),
          render_certificate(applicant)
        ]
      ])

    {:ok, filename} = PdfGenerator.generate(html, page_size: "A4", shell_params: ["--dpi", "300"])
    filename
  end

  defp style(style_map) do
    style_map
    |> Enum.map(fn {key, value} ->
      "#{key}: #{value}"
    end)
    |> Enum.join(";")
  end

  defp render_header() do
    date = DateTime.utc_now()
    date_string = "#{date.year}/#{date.month}/#{date.day}"

    [
      :div,
      %{
        style:
          style(%{
            "display" => "flex",
            "flex-direction" => "column",
            "align-items" => "center",
            "background-color" => "#ffffff",
            "padding" => "20pt",
            "box-shadow" => "0 4pt 6pt rgba(0, 0, 0, 0.1)"
          })
      },
      [
        :h1,
        %{
          style:
            style(%{
              "font-size" => "20pt",
              "color" => @green,
              "margin-top" => "20pt",
              "text-align" => "center",
              "text-transform" => "uppercase",
              "letter-spacing" => "2pt"
            })
        },
        "Certificate of Completion"
      ],
      [
        :h3,
        %{
          style:
            style(%{
              "font-size" => "20pt",
              "margin-top" => "10pt",
              "text-align" => "center",
              "color" => @amber
            })
        },
        "Issued on #{date_string}"
      ]
    ]
  end

  defp render_certificate(applicant) do
    [
      :div,
      %{
        style:
          style(%{
            "display" => "flex",
            "flex-direction" => "column",
            "align-items" => "center",
            "background-color" => "#ffffff",
            "padding" => "40pt",
            "box-shadow" => "0 4pt 6pt rgba(0, 0, 0, 0.1)"
          })
      },
      [
        :p,
        %{
          style:
            style(%{
              "font-size" => "24pt",
              "text-align" => "center",
              "margin-bottom" => "20pt",
              "color" => @foreground
            })
        },
        "This is to certify that"
      ],
      [
        :h2,
        %{
          style:
            style(%{
              "font-size" => "30pt",
              "color" => @green,
              "margin-bottom" => "20pt",
              "text-align" => "center",
              "text-transform" => "uppercase",
              "letter-spacing" => "1pt"
            })
        },
        applicant.applicant
      ],
      [
        :p,
        %{
          style:
            style(%{
              "font-size" => "24pt",
              "text-align" => "center",
              "margin-bottom" => "20pt",
              "color" => @foreground
            })
        },
        "has successfully completed the course"
      ],
      [
        :h3,
        %{
          style:
            style(%{
              "font-size" => "26pt",
              "color" => @amber,
              "margin-bottom" => "20pt",
              "text-align" => "center",
              "font-style" => "italic"
            })
        },
        applicant.quiz
      ],
      [
        :p,
        %{
          style:
            style(%{
              "font-size" => "24pt",
              "text-align" => "center",
              "margin-bottom" => "20pt",
              "color" => @foreground
            })
        },
        "with a score of"
      ],
      [
        :h2,
        %{
          style:
            style(%{
              "font-size" => "30pt",
              "color" => @green,
              "margin-bottom" => "40pt",
              "text-align" => "center",
              "border" => "2pt solid #{@green}",
              "padding" => "10pt 20pt",
              "border-radius" => "5pt"
            })
        },
        "#{applicant.score}%"
      ],
      [
        :div,
        %{
          style:
            style(%{
              "border-top" => "2pt solid #{@amber}",
              "width" => "200pt",
              "margin-top" => "60pt",
              "text-align" => "center"
            })
        },
        [
          :p,
          %{
            style:
              style(%{
                "font-size" => "18pt",
                "margin-top" => "10pt",
                "color" => @foreground
              })
          },
          "Authorized Signature"
        ]
      ]
    ]
  end
end
