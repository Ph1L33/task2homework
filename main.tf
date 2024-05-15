terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "5.27.0"
    }
  }
}

provider "google" {
  # Configuration options
  project     = "theo-lessons-gcp"
  region      = "southamerica-east1"
  zone        = "southamerica-east1-a"
  credentials = "theo-lessons-gcp-dee87fdb5b09.json"
}


resource "google_compute_network" "vpc" {
  name                  = "vpctask2"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "southamerica-east1-subnet" {
  name          = "southamerica-east1-subnet"
  network       = google_compute_network.vpc.self_link
  ip_cidr_range = "10.218.2.0/24"
  region        = "southamerica-east1"
  private_ip_google_access = true
}

resource "google_compute_firewall" "allow-icmp" {
  name    = "icmp-test-firewall"
  network = google_compute_network.vpc.self_link

  allow {
    protocol = "icmp"
  }
  source_ranges = ["0.0.0.0/0"]
  priority      = 600
}

resource "google_compute_firewall" "http" {
  name    = "allow-http"
  network = google_compute_network.vpc.self_link

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }
  source_ranges = ["0.0.0.0/0"]
  priority      = 100
}

resource "google_compute_firewall" "https" {
  name    = "allow-https"
  network = google_compute_network.vpc.self_link

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }
  source_ranges = ["0.0.0.0/0"]
  priority      = 100
}



resource "google_compute_instance" "singlemom304" {
  name         = "singlemom304"
  machine_type = "e2-medium"
  zone         = "southamerica-east1-a"

#  metadata = {
#     startup-script = "scripts/startup.sh"
#   }

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    network    = google_compute_network.vpc.self_link
    subnetwork = google_compute_subnetwork.southamerica-east1-subnet.self_link

    access_config {
      // Ephemeral IP
    }
  }

  tags = ["http-server"]

  # metadata = {
  #   startup-script-url = "${file("startup.sh")}"
  # }

  metadata_startup_script = file("startup.sh")

  # metadata_startup_script = <<-EOF
  #   #!/bin/bash
  #   apt-get update
  #   apt-get install -y apache2
  #   cat <<EOT > /var/www/html/index.html
  #   <html>
  #     <head>
  #       <title>Welcome to My Homepage</title>
  #     </head>
  #     <body>
  #       <h1>Welcome to My Homepage!</h1>
  #       <p>This page is served by Apache on a Google Compute Engine VM instance.</p>
  #     </body>
  #   </html>
  #   EOT
  # EOF
 depends_on = [google_compute_network.vpc,
  google_compute_subnetwork.southamerica-east1-subnet, google_compute_firewall.http]
}



output "vpc" {
  value       = google_compute_network.vpc.self_link
  description = "The ID of the VPC"
}

output "instance_public_ip" {
  value       = google_compute_instance.singlemom304.network_interface[0].access_config[0].nat_ip
  description = "The public IP address of the web server"
}

output "instance_subnet" {
  value       = google_compute_instance.singlemom304.network_interface[0].subnetwork
  description = "The subnet of the VM instance"
}

output "instance_internal_ip" {
  value       = google_compute_instance.singlemom304.network_interface[0].network_ip
  description = "The internal IP address of the VM instance"
}
