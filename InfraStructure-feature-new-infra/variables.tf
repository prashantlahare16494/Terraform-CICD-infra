variable "region" {

}

variable "access_key" {

}

variable "secret_key" {

}

variable "PATH_TO_PRIVATE_KEY" {
  default = "infra_key"
}

variable "PATH_TO_PUBLIC_KEY" {
  default = "infra_key.pub"
}
 
variable "jenkins-server" {
} 

variable "sonarqube-server" {
}

variable "nexus-server" {  
}
