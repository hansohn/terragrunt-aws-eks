#--------------------------------------------------------------
# Main
#--------------------------------------------------------------

locals {
  prefix = "Hi"
  greeting = format(
    "%s %s!",
    local.prefix,
    var.addressee
  )
}

resource "random_pet" "this" {
  keepers = {
    greeting = local.greeting
  }
}
