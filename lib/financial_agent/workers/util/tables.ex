defmodule FinincialAgent.Workers.Util.Tables do
  def titles(), do: ["Mr", "Mrs", "Ms", "Dr", "Prof"]
  def genders(), do: [%{name: "Male", key: "M"}, %{name: "Female", key: "F"}]

  def marital_status(),
    do: [
      %{name: "Single", key: "SINGLE"},
      %{name: "Married", key: "MARRIED"},
      %{name: "Divorced", key: "DIVORCED"},
      %{name: "Widow", key: "WINDOW"},
      %{name: "Widower", key: "WINDOWER"}
    ]

  def relationships(),
    do: [
      %{key: "DAUGHTER", name: "DAUGHTER"},
      %{key: "HUSBAND", name: "HUSBAND"},
      %{key: "SON", name: "SON"},
      %{key: "WIFE", name: "WIFE"}
    ]

  def company_docs do
    [
      %{name: "Company Registration Certificate", key: "reg_cert", is_required: true},
      %{name: "Article of Association", key: "art_ass", is_required: true},
      %{name: "Stamped PACRA Printout/Form", key: "pacra", is_required: true},
      %{name: "Tax Clearance Certificate", key: "cle_cert", is_required: true},
      %{name: "Certified Copy of NRCs ", key: "nrc", is_required: false},
      %{name: "Passport Size Photos", key: "pass_size_photo", is_required: true},
      %{name: "Proof of Residential Address ", key: "res_add", is_required: false},
      %{name: "Confirmation of Operating Address for Company", key: "oper_add", is_required: true}
    ]
  end

  def company_docs(key) do
    case key do
      "reg_cert" ->
        %{name: "Company Registration Certificate", key: "reg_cert", is_required: true}

      "art_ass" ->
        %{name: "Article of Association", key: "art_ass", is_required: true}

      "pacra" ->
        %{name: "Stamped PACRA Printout/Form3", key: "pacra", is_required: true}

      "cle_cert" ->
        %{name: "Tax Clearance Certificate", key: "cle_cert", is_required: true}

      "nrc" ->
        %{name: "Certified Copy of NRCs ", key: "nrc", is_required: false}

      "pass_size_photo" ->
        %{name: "Passport Size Photos", key: "pass_size_photo", is_required: true}

      "res_add" ->
        %{name: "Proof of Residential Address ", key: "res_add", is_required: false}

      "oper_add" ->
        %{
          name: "Confirmation of Operating Address for Company",
          key: "oper_add",
          is_required: true
        }
    end
  end

  def client_docs do
    [
      %{name: "Certified Copy NRC ", key: "nrc", is_required: true},
      %{name: "Passport Size Photo", key: "pass_size_photo", is_required: true},
      %{name: "Proof of Residential Address", key: "proof_of_res", is_required: true},
      %{name: "Signature Photo ", key: "signature", is_required: true}
    ]
  end

  def client_docs(key) do
    case key do
      "nrc" ->
        %{name: "Certified copy NRC ", key: "nrc", is_required: true}

      "pass_size_photo" ->
        %{name: "Passport Size Photo", key: "pass_size_photo", is_required: true}

      "proof_of_res" ->
        %{name: "Proof of Residential address", key: "proof_of_res", is_required: true}

      "signature" ->
        %{name: "Signature Photo ", key: "signature", is_required: true}
    end
  end

  def marital_status(s) do
    case s do
      "Divorced" -> "Divorced"
      "Married" -> "Married"
      "Single" -> "Single"
      "Widow" -> "Widow"
      "Widower" -> "Widower"
    end
  end

  def provinces() do
    [
      %{code: "1", name: "LUSAKA"},
      %{code: "2", name: "CENTRAL"},
      %{code: "3", name: "COPPERBELT"},
      %{code: "4", name: "MUCHINGA"},
      %{code: "5", name: "LUAPULA"},
      %{code: "6", name: "EASTERN"},
      %{code: "7", name: "NORTH WESTERN"},
      %{code: "8", name: "WESTERN"},
      %{code: "9", name: "SOUTHERN"},
      %{code: "10", name: "NORTHERN"}
    ]
  end

  def town(code) do
    case code do
      "101" -> "CHADIZA"
      "102" -> "CHAMA"
      "103" -> "CHAMBESHI"
      "104" -> "CHAVUMA"
      "198" -> "CHIBOMBO"
      "215" -> "CHIENGI"
      "105" -> "CHILANGA"
      "106" -> "CHILILABOMBWE"
      "107" -> "CHILUBI"
      "108" -> "CHILUBI ISLAND"
      "109" -> "CHINGOLA"
      "110" -> "CHINSALI"
      "111" -> "CHIPATA"
      "112" -> "CHIRUNDU"
      "113" -> "CHISAMBA"
      "114" -> "CHISEKESI"
      "218" -> "CHITAMBO"
      "115" -> "CHIZELA"
      "116" -> "CHIZERA"
      "117" -> "CHOMA"
      "118" -> "CHONGWE"
      "119" -> "FEIRA"
      "120" -> "GWEMBE"
      "121" -> "IKELENGE"
      "122" -> "ISOKA"
      "123" -> "ITEZHI TEZHI"
      "202" -> "ITIMPI"
      "124" -> "KABOMPO"
      "125" -> "KABWE"
      "126" -> "KAFUE"
      "127" -> "KALABO"
      "128" -> "KALOMO"
      "129" -> "KALULUSHI"
      "130" -> "KANONA"
      "131" -> "KAOMA"
      "132" -> "KAPIRI MPOSHI"
      "133" -> "KAPUTA"
      "134" -> "KASAMA"
      "135" -> "KASEMPA"
      "136" -> "KATETE"
      "137" -> "KAWAMBWA"
      "138" -> "KAZEMBE"
      "139" -> "KAZIMULE"
      "140" -> "KITWE"
      "141" -> "LILAYI"
      "142" -> "LIMULUNGA"
      "143" -> "LIVINGSTONE"
      "144" -> "LUAMPA"
      "145" -> "LUANGWA"
      "219" -> "LUANO"
      "146" -> "LUANSHYA"
      "209" -> "LUBWE"
      "217" -> "LUFWANYAMA"
      "147" -> "LUKULU"
      "148" -> "LUNDAZI"
      "1" -> "LUSAKA"
      "150" -> "LUWINGU"
      "151" -> "MAAMBA"
      "152" -> "MAGOYE"
      "207" -> "MALOLE"
      "216" -> "MAMBWE"
      "153" -> "MANSA"
      "211" -> "MANYINGA"
      "154" -> "MAPANZA"
      "201" -> "MASAITI"
      "155" -> "MAZABUKA"
      "156" -> "MBABALA"
      "157" -> "MBALA"
      "158" -> "MFUWE"
      "214" -> "MILENGE"
      "159" -> "MKUSHI"
      "160" -> "MKUSHI BOMA"
      "161" -> "MKUSHI RIVER"
      "162" -> "MONGU"
      "163" -> "MONZE"
      "164" -> "MPIKA"
      "200" -> "MPONGWE"
      "165" -> "MPOROKOSO"
      "166" -> "MPULUNGU"
      "167" -> "MUFULIRA"
      "199" -> "MUFUMBWE"
      "212" -> "MUKONCHI"
      "169" -> "MUMBWA"
      "210" -> "MUNGWI"
      "170" -> "MUNUNGA"
      "204" -> "MUSHOTA"
      "208" -> "MWANDI"
      "171" -> "MWENSE"
      "172" -> "MWINILUNGA"
      "173" -> "NAKONDE"
      "174" -> "NAMALUNDU GORGE"
      "175" -> "NAMUSHAKENDE"
      "176" -> "NAMWALA"
      "205" -> "NANGOMA"
      "177" -> "NCHELENGE"
      "178" -> "NDOLA"
      "179" -> "NEGANEGA"
      "220" -> "NGABWE"
      "213" -> "NSUMBU"
      "180" -> "NYIMBA"
      "181" -> "PEMBA"
      "182" -> "PETAUKE"
      "183" -> "PUTA"
      "203" -> "RUFUNSA"
      "184" -> "SAMFYA"
      "185" -> "SENANGA"
      "186" -> "SERENJE"
      "187" -> "SESHEKE"
      "188" -> "SHANGOMBO"
      "189" -> "SHIBUYUNJI"
      "206" -> "SHIWA NGANDU"
      "190" -> "SIAVONGA"
      "191" -> "SINAZEZE"
      "192" -> "SINAZONGWE"
      "193" -> "SINDA"
      "194" -> "SOLWEZI"
      "195" -> "ZAMBEZI"
      "196" -> "ZIMBA"
    end
  end
end
