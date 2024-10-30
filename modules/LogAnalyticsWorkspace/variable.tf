variable "prefix" {
  description = "A prefix for resource names."
}
variable "location" {
  description = "The location/region where the resources will be created."
}
variable "resource_group_name" {
  description = "Resource Group name."
}
variable "tags" {
  description = "Tags for resources."
}
variable "action_grp_member" {
  description = "Defines the members of the action group for notifications or alerts."
}
