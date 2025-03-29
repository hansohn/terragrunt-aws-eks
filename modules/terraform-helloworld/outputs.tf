#--------------------------------------------------------------
# Outputs
#--------------------------------------------------------------

output "random_pet_greeting" {
  value       = random_pet.this.id
  description = "Random Pet Id"
}
