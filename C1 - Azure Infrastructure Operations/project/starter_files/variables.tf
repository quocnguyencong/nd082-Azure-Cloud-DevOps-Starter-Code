variable "prefix" {
    default = "udacity-terraform"
}

variable "location" {
    default = "East Asia"
}

variable "username" {
    default = "adminuser"
}

variable "password" {
    default = "P@ssw0rd1234!"
}

variable "packerImage" {
    default = "myPackerImage"
}

variable "packerImageId" {
    default = "/subscriptions/0946c94a-63ec-4f75-aebc-6183a4abc13af/resourceGroups/udacity-resource-group-test/providers/Microsoft.Compute/images/myPackerImage"
}

variable "packerResourceGroup" {
    default = "udacity-resource-group-test"
}

variable application_port {
    default = 80
}
