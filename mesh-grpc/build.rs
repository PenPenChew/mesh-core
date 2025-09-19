fn main() -> Result<(), Box<dyn std::error::Error>> {
    let out_dir = std::env::var("OUT_DIR").unwrap();
    tonic_build::configure()
        .build_server(true)
        .build_client(true)
        .file_descriptor_set_path(format!("{}/mesh_descriptor.bin", out_dir))
        .compile_protos(
            &[
                "proto/mesh/v1/data.proto",
                "proto/mesh/v1/control.proto",
            ],
            &["proto"],
        )?;
    Ok(())
}