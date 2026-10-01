# =============================================================================
#  modules/network/variables.tf  –  modulens kontrakt inn
# -----------------------------------------------------------------------------
#  Tommelfingerregel: alt modulen IKKE kan vite selv, må stå her. Og verdier
#  som MÅ komme utenfra, skal ikke ha en `default` – en default gjør det bare
#  lett å glemme å sette dem.
# =============================================================================

variable "rg_name" {
  type        = string
  description = "Navnet på ressursgruppa nettverket skal ligge i."
  # Ingen default: modulen skal kunne plasseres i hvilken som helst
  # ressursgruppe, og den oppretter den aldri selv.
}

variable "location" {
  type        = string
  description = "Azure-regionen ressursene opprettes i."
}

variable "base_name" {
  type        = string
  description = <<-TEKST
    Navnegrunnlaget miljøet leverer, f.eks. "oppg3-dev-tim".
    Modulen setter selv på prefiksene "vnet-", "snet-" og "nsg-".
  TEKST
}

variable "address_space" {
  type        = string
  description = "Adresserommet vnet-et disponerer, som CIDR – f.eks. 10.10.0.0/16."

  # Ingen default, av samme grunn som rg_name ikke har det. Hvilket adresserom
  # et nettverk skal ha, er en GLOBAL beslutning: den handler om alt annet som
  # finnes i organisasjonen, ikke om dette ene nettverket. Derfor kan ikke
  # modulen ta den.
  #
  # En default her ville betydd at alle miljøer arvet samme adresse – og da er
  # vi tilbake til at dev og prod ikke kan peeres den dagen de skal.

  validation {
    # can() returnerer true hvis uttrykket lar seg regne ut, false hvis det
    # feiler. Slik fanger vi en ugyldig CIDR allerede ved `plan`, i stedet for
    # at Azure avviser den midt i en `apply`.
    condition     = can(cidrhost(var.address_space, 0))
    error_message = "address_space må være en gyldig CIDR-blokk, f.eks. 10.10.0.0/16."
  }
}

variable "subnets" {
  type        = map(number)
  description = <<-TEKST
    Subnettene som skal opprettes: navn => netnum innenfor adresserommet.
    Nøkkelen er subnettets identitet og skal ligge i ro; netnum bestemmer
    hvilken del av adresserommet det får.
  TEKST

  # Merk hva datastrukturen gjør for oss. To parallelle lister – ett navn og
  # ett prefiks – kan komme i utakt uten at noe stopper det. Et map kan ikke:
  # navnet og verdien holdes ikke sammen av rekkefølge, men av å stå på samme
  # linje.
}

variable "subnet_newbits" {
  type        = number
  default     = 8
  description = <<-TEKST
    Hvor mange bit subnettene forlenger adresserommet med.
    8 gir /24 ut av et /16, altså 256 mulige subnett.
  TEKST

  # Denne kunne vært skrevet som tallet 8 rett inn i cidrsubnet(). Den ligger
  # som variabel for at modulen ikke skal være låst til /24 – men å hardkode
  # 8 er en helt akseptabel løsning på oppgaven.
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Felles tags fra miljøet. Tags arves ikke fra ressursgruppa i Azure."
}
