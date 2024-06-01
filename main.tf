terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "5.28.0"
    }
  }
}

provider "google" {
  # Configuration options
  project     = "third-wharf-422001"
  region      = "eu-west1"
  zone        = "eu-west1-b"
  credentials = "third-wharf-422001-430bd7a56f65.json"
}


resource "google_compute_network" "vpc" {
  name                  = "vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "eu-west1b-subnet" {
  name          = "eu-west1b-subnet"
  network       = google_compute_network.vpc.self_link
  ip_cidr_range = "10.121.2.0/24"
  region        = "europe-west1"
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

resource "google_compute_instance" "task_2_instance" {
  name         = "task-2-instance"
  machine_type = "e2-medium"
  zone         = "europe-west1-b"


  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    network    = google_compute_network.vpc.self_link
    subnetwork = google_compute_subnetwork.eu-west1b-subnet.self_link

    access_config {
      // Ephemeral IP
    }
  }

  tags = ["http-server"]


  metadata_startup_script = file("startup.sh")

 depends_on = [google_compute_network.vpc,
  google_compute_subnetwork.eu-west1b-subnet, google_compute_firewall.http]
}



output "vpc" {
  value       = google_compute_network.vpc.self_link
  description = "The ID of the VPC"
}

output "instance_public_ip" {
  value       = google_compute_instance.task_2_instance.network_interface[0].access_config[0].nat_ip
  description = "The public IP address of the web server"
}

output "instance_subnet" {
  value       = google_compute_instance.task_2_instance.network_interface[0].subnetwork
  description = "The subnet of the VM instance"
}

output "instance_internal_ip" {
  value       = google_compute_instance.task_2_instance.network_interface[0].network_ip
  description = "The internal IP address of the VM instance"
}
