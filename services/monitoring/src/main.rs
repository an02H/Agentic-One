// ============================================================
// Agentic-One — Lab Monitor Micro-service
// Port : 7070 | Mode : ECO (basse consommation)
// Rôle : Exposition métriques CPU/RAM pour Dashboard UI
// ============================================================
use actix_web::{get, App, HttpResponse, HttpServer, Responder, middleware};
use sysinfo::{System, SystemExt, CpuExt};
use serde::Serialize;
use std::sync::Mutex;

/// Struct des métriques exposées via GET /metrics (JSON)
#[derive(Serialize)]
struct Stats {
    cpu_usage:  f32,   // % utilisation CPU globale
    ram_used:   u64,   // RAM utilisée en Mo
    ram_total:  u64,   // RAM totale en Mo
    swap_used:  u64,   // SWAP utilisé en Mo (doit rester à 0)
}

/// GET /metrics — Retourne les métriques système en JSON
/// Utilisé par n8n et le Dashboard HTML
#[get("/metrics")]
async fn get_metrics() -> impl Responder {
    let mut sys = System::new_all();
    sys.refresh_all();

    let stats = Stats {
        cpu_usage: sys.global_cpu_info().cpu_usage(),
        ram_used:  sys.used_memory()  / 1024 / 1024,
        ram_total: sys.total_memory() / 1024 / 1024,
        swap_used: sys.used_swap()    / 1024 / 1024,
    };

    HttpResponse::Ok()
        .insert_header(("Access-Control-Allow-Origin", "*"))
        .json(stats)
}

/// GET /health — Endpoint de santé pour Portainer/n8n
#[get("/health")]
async fn health() -> impl Responder {
    HttpResponse::Ok()
        .insert_header(("Content-Type", "application/json"))
        .body(r#"{"status":"ok","service":"lab_monitor","version":"0.1.0"}"#)
}

/// GET / — Sert le Dashboard HTML (temporaire — désactivable en prod)
#[get("/")]
async fn index() -> impl Responder {
    HttpResponse::Ok()
        .content_type("text/html; charset=utf-8")
        .body(include_str!("index.html"))
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    println!("╔══════════════════════════════════════════════╗");
    println!("║  Agentic-One Lab Monitor — v0.1.0            ║");
    println!("║  Listening on http://0.0.0.0:7070            ║");
    println!("║  Endpoints : /  /metrics  /health            ║");
    println!("╚══════════════════════════════════════════════╝");

    HttpServer::new(|| {
        App::new()
            .service(index)
            .service(get_metrics)
            .service(health)
    })
    .bind("0.0.0.0:7070")?
    .run()
    .await
}

// ============================================================
// TESTS UNITAIRES
// ============================================================
#[cfg(test)]
mod tests {
    use actix_web::{test, App};
    use super::*;

    #[actix_web::test]
    async fn test_health_endpoint() {
        let app = test::init_service(App::new().service(health)).await;
        let req = test::TestRequest::get().uri("/health").to_request();
        let resp = test::call_service(&app, req).await;
        assert!(resp.status().is_success());
    }

    #[actix_web::test]
    async fn test_metrics_returns_json() {
        let app = test::init_service(App::new().service(get_metrics)).await;
        let req = test::TestRequest::get().uri("/metrics").to_request();
        let resp = test::call_service(&app, req).await;
        assert!(resp.status().is_success());
    }
}
