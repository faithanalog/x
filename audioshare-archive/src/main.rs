use serde::{Serialize, Deserialize};
use std::env;
use std::fs;
use reqwest::blocking as reqwest;

#[derive(Serialize, Deserialize, Debug)]
struct FileEntry {
    path: String,
    name: String
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let args: Vec<String> = env::args().collect();

    if args.len() != 2 {
        eprintln!("Usage: {} <input_file>", args[0]);
        return Ok(());
    }

    let baseurl = &args[1];
    
    let entries: Vec<FileEntry> = reqwest::get(format!("{}/list?path=%2F", baseurl))?.json()?;
    let count = entries.len();
    
    for (i, entry) in entries.iter().enumerate() {
        println!("Downloading {} / {}: {}", i + 1, count, entry.name);
        let mut file = fs::File::create(&entry.name)?;
        reqwest::get(format!("{}/download?path={}", baseurl, entry.path))?.copy_to(&mut file)?;
    }

    Ok(())
}
