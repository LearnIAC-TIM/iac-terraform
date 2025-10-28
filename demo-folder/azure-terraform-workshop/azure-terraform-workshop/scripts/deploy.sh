#!/bin/bash
# Deploy script for Azure Terraform Workshop
# Forenkler terraform kommandoer med validering og error handling

set -e

# Farger for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_header() {
    echo ""
    echo "========================================"
    echo "$1"
    echo "========================================"
    echo ""
}

# Sjekk at vi er i environments/dev directory
if [ ! -f "main.tf" ]; then
    print_error "Dette scriptet må kjøres fra environments/dev directory!"
    exit 1
fi

# Funksjon for å vise hjelp
show_help() {
    echo "Bruk: ./deploy.sh [kommando]"
    echo ""
    echo "Kommandoer:"
    echo "  init      - Initialiser Terraform"
    echo "  validate  - Valider Terraform konfigurasjon"
    echo "  plan      - Vis hva som vil bli endret"
    echo "  apply     - Deploy infrastrukturen"
    echo "  destroy   - Slett all infrastruktur"
    echo "  output    - Vis outputs fra deployment"
    echo "  refresh   - Oppdater state"
    echo "  help      - Vis denne hjelpeteksten"
    echo ""
}

# Funksjon for init
do_init() {
    print_header "Terraform Init"
    terraform init -upgrade
    print_success "Init fullført"
}

# Funksjon for validate
do_validate() {
    print_header "Terraform Validate"
    
    # Format check
    print_info "Sjekker formatering..."
    if terraform fmt -check -recursive; then
        print_success "Formatering OK"
    else
        print_warning "Noen filer trenger formatering"
        echo "Kjør: terraform fmt -recursive"
    fi
    
    # Validate
    print_info "Validerer konfigurasjon..."
    terraform validate
    print_success "Validering OK"
}

# Funksjon for plan
do_plan() {
    print_header "Terraform Plan"
    terraform plan -out=tfplan
    print_success "Plan opprettet: tfplan"
    echo ""
    print_info "For å deploye: ./deploy.sh apply"
}

# Funksjon for apply
do_apply() {
    print_header "Terraform Apply"
    
    # Sjekk om det finnes en plan-fil
    if [ -f "tfplan" ]; then
        print_info "Bruker eksisterende plan-fil..."
        terraform apply tfplan
        rm tfplan
    else
        print_warning "Ingen plan-fil funnet. Oppretter ny plan først..."
        terraform plan -out=tfplan
        echo ""
        read -p "Fortsett med apply? (y/n) " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            terraform apply tfplan
            rm tfplan
        else
            print_info "Apply avbrutt"
            exit 0
        fi
    fi
    
    print_success "Apply fullført!"
    echo ""
    print_info "Se outputs med: ./deploy.sh output"
}

# Funksjon for destroy
do_destroy() {
    print_header "Terraform Destroy"
    print_warning "ADVARSEL: Dette vil slette all infrastruktur!"
    print_warning "Resource Group, Storage Account og Key Vault vil IKKE bli slettet."
    echo ""
    read -p "Er du sikker på at du vil fortsette? Skriv 'yes' for å bekrefte: " -r
    echo ""
    if [ "$REPLY" = "yes" ]; then
        terraform destroy
        print_success "Destroy fullført"
    else
        print_info "Destroy avbrutt"
    fi
}

# Funksjon for output
do_output() {
    print_header "Terraform Outputs"
    terraform output
}

# Funksjon for refresh
do_refresh() {
    print_header "Terraform Refresh"
    terraform refresh
    print_success "Refresh fullført"
}

# Parse command
case "${1:-help}" in
    init)
        do_init
        ;;
    validate)
        do_validate
        ;;
    plan)
        do_validate
        do_plan
        ;;
    apply)
        do_apply
        ;;
    destroy)
        do_destroy
        ;;
    output)
        do_output
        ;;
    refresh)
        do_refresh
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        print_error "Ukjent kommando: $1"
        echo ""
        show_help
        exit 1
        ;;
esac
