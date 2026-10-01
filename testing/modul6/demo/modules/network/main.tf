# =============================================================================
#  modules/network/  –  nettverkskomponenten
# -----------------------------------------------------------------------------
#  Denne modulen vet ingenting om hvilket miljø den kjører i. Den får utlevert
#  en ressursgruppe, en region, et navnegrunnlag og ETT adresserom – og regner
#  ut resten selv. Det er nettopp derfor den samme mappa kan brukes av dev,
#  test og prod uten en eneste endring.
# =============================================================================

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.4"
    }
  }
}

# Legg merke til at det ikke står noen `provider "azurerm"`-blokk her.
# En child module KREVER en provider, men KONFIGURERER den ikke – selve
# oppsettet (features, subscription) arves fra root-modulen som kaller den,
# altså fra stacks/nettverk/. Dette er skillet fra modul 2.

# -----------------------------------------------------------------------------
#  Virtuelt nettverk
# -----------------------------------------------------------------------------
resource "azurerm_virtual_network" "vnet" {
  # K7: navnet bygges HER, ikke i miljømappa. Miljøet leverer bestanddelene
  # (var.base_name = f.eks. "oppg3-dev-tim"), og modulen vet at et vnet skal ha
  # prefikset "vnet-". Slik slipper hver miljømappe å kunne navnereglene for
  # hver eneste ressurstype stacken inneholder.
  name                = format("vnet-%s", var.base_name)
  location            = var.location
  resource_group_name = var.rg_name

  # K2: ingen adresse skrevet for hånd. Verdien kommer utenfra.
  #
  # Variabelen er én streng, mens argumentet er en liste. Et vnet KAN ha flere
  # adresserom, men vi tar imot ett – fordi vi skal regne på det lenger nede,
  # og cidrsubnet() tar ett prefiks om gangen.
  address_space = [var.address_space]

  tags = var.tags
}

# -----------------------------------------------------------------------------
#  Subnett – én blokk, mange ressurser
# -----------------------------------------------------------------------------
resource "azurerm_subnet" "subnet" {
  # K3: ÉN resource-blokk, ikke én per subnet. Terraform lager én instans per
  # nøkkel i mapet, og nøkkelen blir instansens identitet i state:
  #
  #     module.stack.module.network.azurerm_subnet.subnet["web"]
  #
  # Med `count` ville det stått ["0"] – og da flytter identiteten seg så snart
  # noen setter inn eller fjerner et element i midten av lista.
  for_each = var.subnets

  name                 = format("snet-%s-%s", each.key, var.base_name)
  resource_group_name  = var.rg_name
  virtual_network_name = azurerm_virtual_network.vnet.name

  # cidrsubnet(prefix, newbits, netnum)
  #   prefix  – adresserommet miljøet ga oss, f.eks. 10.10.0.0/16
  #   newbits – hvor mange bit vi forlenger prefikset med: /16 + 8 = /24
  #   netnum  – hvilken av de 256 blokkene vi vil ha, fra 0 og oppover
  #
  # K4: netnum kommer fra mapet. Det er DATA som noen har skrevet ned, ikke en
  # posisjon Terraform har talt seg fram til. Derfor beholder "data" adressen
  # sin selv om noen setter inn et nytt subnet alfabetisk foran det.
  #
  # Fristelsen er å bruke index(keys(var.subnets), each.key) og slippe å skrive
  # tallene. Ikke gjør det: da er du tilbake til posisjon som identitet, og et
  # subnet som bytter adresse må rives og bygges på nytt.
  address_prefixes = [
    cidrsubnet(var.address_space, var.subnet_newbits, each.value)
  ]
}

# -----------------------------------------------------------------------------
#  Network security group
# -----------------------------------------------------------------------------
resource "azurerm_network_security_group" "nsg" {
  name                = format("nsg-%s", var.base_name)
  location            = var.location
  resource_group_name = var.rg_name
  tags                = var.tags

  # Ingen egne regler her. Azures standardregler slipper trafikk innenfor
  # det virtuelle nettverket og nekter innkommende trafikk fra internett –
  # som er det vi vil ha så lenge ingen skal logge på maskinen utenfra.
}

resource "azurerm_subnet_network_security_group_association" "snet_nsg" {
  # K5: for_each kjøres RETT OVER subnet-ressursen, ikke over var.subnets en
  # gang til.
  #
  # En ressurs som har for_each, ER et map fra nøkkel til ressurs. Vi arver
  # derfor nøklene, og koblingene kan aldri komme i utakt med subnettene:
  # legger noen til et subnet, følger koblingen med av seg selv.
  #
  # each.value er hele subnet-objektet – derfor each.value.id.
  for_each = azurerm_subnet.subnet

  subnet_id                 = each.value.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}
