provider "google" {
  credentials = file("~/.gcp/hc-defd8281f2e745458453843e077-b1e13b850b80.json")
  project     = "hc-defd8281f2e745458453843e077"
  region      = "europe-west4"
  zone        = "europe-west4-a"
}

resource "google_compute_network" "vpc" {
  name                    = "vpc"
  auto_create_subnetworks = "false"
  routing_mode            = "GLOBAL"
}

resource "google_compute_subnetwork" "public_subnet" {
  name          = "public-subnet"
  ip_cidr_range = "10.0.1.0/24"
  network       = google_compute_network.vpc.name
}

resource "google_compute_firewall" "allow-ssh" {
  name    = "allow-ssh"
  network = google_compute_network.vpc.name
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags = ["consul", "nomad", "client"]
}

data "template_file" "install-hashicorp-repository" {
  template = file("./scripting/install-hashicorp-repository.sh")
}

data "template_file" "install-docker" {
  template = file("./scripting/install-docker.sh")
}

data "template_file" "install-consul" {
  template = file("./scripting/install-consul.sh")
}

data "template_file" "install-nomad" {
  template = file("./scripting/install-nomad.sh")
}

data "template_file" "install-bash-environment-hashicorp" {
  template = file("./scripting/install-bash-environment-hashicorp.sh")
}

data "template_cloudinit_config" "consul-nomad-client" {
  gzip          = false
  base64_encode = false

  part {
    content_type = "text/cloud-boothook"
    filename     = "install-hashicorp-repository.sh"
    content      = data.template_file.install-hashicorp-repository.rendered # Hashicorp repo
  }

  part {
    content_type = "text/cloud-boothook"
    filename     = "install-consul.sh"
    content      = data.template_file.install-consul.rendered # install consul
  }

  part {
    content_type = "text/cloud-boothook"
    filename     = "install-nomad.sh"
    content      = data.template_file.install-nomad.rendered # install nomad
  }

  part {
    content_type = "text/x-shellscript"
    filename     = "install-bash-environment-hashicorp.sh"
    content      = data.template_file.install-bash-environment-hashicorp.rendered # bash HTTP address consul & nomad
  }
}

resource "google_compute_instance" "consul" {
  name         = "consul"
  machine_type = "n1-standard-1"

  tags = ["consul"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
    }
  }

  network_interface {
    network       = google_compute_network.vpc.name
    subnetwork    = google_compute_subnetwork.public_subnet.name
    access_config {}
  }

  service_account {
    # https://developers.google.com/identity/protocols/oauth2/scopes
    scopes = [
      "https://www.googleapis.com/auth/compute.readonly",
    ]
  }

  metadata = {
    ssh-keys = format("%s:%s", "ubuntu", file("~/.ssh/id_ed25519.pub"))
    startup-script = data.template_cloudinit_config.consul-nomad-client.rendered
  }
}

resource "google_compute_instance" "nomad" {
  name         = "nomad"
  machine_type = "n1-standard-1"

  tags = ["nomad"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
    }
  }

  network_interface {
    network       = google_compute_network.vpc.name
    subnetwork    = google_compute_subnetwork.public_subnet.name
    access_config {}
  }

  service_account {
    # https://developers.google.com/identity/protocols/oauth2/scopes
    scopes = [
      "https://www.googleapis.com/auth/compute.readonly",
    ]
  }
  
  metadata = {
    ssh-keys = format("%s:%s", "ubuntu", file("~/.ssh/id_ed25519.pub"))
    startup-script = data.template_cloudinit_config.consul-nomad-client.rendered
  }
}

resource "google_compute_instance" "client" {
  name         = "client"
  machine_type = "n1-standard-1"

  tags = ["client"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
    }
  }

  network_interface {
    network       = google_compute_network.vpc.name
    subnetwork    = google_compute_subnetwork.public_subnet.name
    access_config {}
  }

  service_account {
    # https://developers.google.com/identity/protocols/oauth2/scopes
    scopes = [
      "https://www.googleapis.com/auth/compute.readonly",
    ]
  }
  
  metadata = {
    ssh-keys = format("%s:%s", "ubuntu", file("~/.ssh/id_ed25519.pub"))
    startup-script = data.template_cloudinit_config.consul-nomad-client.rendered
  }
}

output "SSH-consul" {
    value = "ssh -i ~/.ssh/id_ed25519 -o 'StrictHostKeyChecking no' ubuntu@${google_compute_instance.consul.network_interface.0.access_config.0.nat_ip}"
}

output "SSH-nomad" {
    value = "ssh -i ~/.ssh/id_ed25519 -o 'StrictHostKeyChecking no' ubuntu@${google_compute_instance.nomad.network_interface.0.access_config.0.nat_ip}"
}

output "SSH-client" {
    value = "ssh -i ~/.ssh/id_ed25519 -o 'StrictHostKeyChecking no' ubuntu@${google_compute_instance.client.network_interface.0.access_config.0.nat_ip}"
}