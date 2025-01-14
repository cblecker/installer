resource "google_compute_address" "cluster_ip" {
  name         = "${var.cluster_id}-cluster-ip"
  address_type = "INTERNAL"
  subnetwork   = google_compute_subnetwork.master_subnet[0].self_link
}

resource "google_compute_health_check" "api_internal" {
  name = "${var.cluster_id}-api-internal"

  https_health_check {
    port         = 6443
    request_path = "/readyz"
  }
}

resource "google_compute_region_backend_service" "api_internal" {
  name = "${var.cluster_id}-api-internal"

  load_balancing_scheme = "INTERNAL"
  protocol              = "TCP"
  timeout_sec           = 120

  dynamic "backend" {
    for_each = var.master_instance_groups

    content {
      group = backend.value
    }
  }

  health_checks = [google_compute_health_check.api_internal.self_link]
}

resource "google_compute_forwarding_rule" "api_internal" {
  name = "${var.cluster_id}-api-internal"

  ip_address      = google_compute_address.cluster_ip.address
  backend_service = google_compute_region_backend_service.api_internal.self_link
  ports           = ["6443", "22623"]
  subnetwork      = google_compute_subnetwork.master_subnet[0].self_link

  load_balancing_scheme = "INTERNAL"
}
