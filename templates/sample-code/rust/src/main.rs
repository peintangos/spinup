use std::io::{Read, Write};
use std::net::TcpListener;

fn main() {
    let port = 8080;
    let listener = TcpListener::bind(format!("0.0.0.0:{}", port)).unwrap();
    println!("Server running at http://localhost:{}", port);

    for stream in listener.incoming() {
        let mut stream = stream.unwrap();
        let mut buf = [0u8; 1024];
        stream.read(&mut buf).unwrap();

        let body = r#"{"message":"Hello from Rust!"}"#;
        let response = format!(
            "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: {}\r\n\r\n{}",
            body.len(),
            body
        );
        stream.write_all(response.as_bytes()).unwrap();
    }
}
