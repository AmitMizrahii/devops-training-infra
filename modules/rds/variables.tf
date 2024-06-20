#######################
# GENERAL CONFIGURATION
#######################

variable "project_name" {
  type        = string
  description = "The project name, using to tag the entities"
}


#######################
# DB CONFIGURATION
#######################
variable "instance_class" {
  type        = string
  default     = "db.t3.micro"
  description = "Type of the database instance class"

  validation {
    condition     = contains(["db.t2.micro", "db.t3.micro"], var.instance_class)
    error_message = "Only db.t2.micro or db.t3.micro are allowed due to free tier, BUT you supplied: ${var.instance_class}"
  }
}
variable "storage_size" {
  type        = number
  default     = 10
  description = "DB storage size in GB, must be between 5 to 10 GB"
  validation {
    condition     = var.storage_size >= 5 && var.storage_size <= 10
    error_message = "DB storage size must be between 5GB to 10GB, BUT you supplied: ${var.storage_size}"
  }
}

variable "engine" {
  type        = string
  default     = "postgres-latest"
  description = "DB engine version"
  validation {
    condition     = contains(["postgres-latest", "postgres-14"], var.engine)
    error_message = "DB engine must be postgres-latest or postgres-14, BUT you supplied: ${var.engine}"

  }
}

#######################
# DB CREDENTIALS
#######################

variable "credentials" {
  type = object({
    username = string
    password = string
  })
  description = "DB login info"
  sensitive   = true

  validation {
    condition = (
      length(regexall("[a-zA-Z]+", var.credentials.password)) > 0
      && length(regexall("[0-9]+", var.credentials.password)) > 0
      && length(regexall("^[a-zA-Z0-9+_?-]{8,}$", var.credentials.password)) > 0
    )
    error_message = <<-EOT
    Password must comply with the following format:

    1. Contain at least 1 character
    2. Contain at least 1 digit
    3. Be at least 8 characters long
    4. Contain only the following characters: a-z, A-Z, 0-9, +, _, ?, -
    EOT
  }
}

#######################
# DB NETWOEK
#######################

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet Ids to deploy the RDS instance in"
}

variable "security_group_ids" {
  type        = list(string)
  description = "Secutity group Ids to attach to the RDS instance"
}
