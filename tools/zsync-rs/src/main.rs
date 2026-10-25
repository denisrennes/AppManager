//! zsync client for AppManager: the zsync-rs library plus progress output.
//!
//! Arguments: `-i <seed>` (repeatable), `-o <output>` and the .zsync URL.
//! Prints `progress <done> <total>` lines on stdout, where done counts bytes
//! already assembled, including blocks reused from the seeds.
//! The upstream zsync-rs CLI downloads every range in one call and so only
//! reports progress once, at the end.

use std::path::PathBuf;
use std::sync::Mutex;
use std::time::{Duration, Instant};

use zsync_rs::ZsyncAssembly;

// The library reports every block; the app redraws at most this often anyway.
const PROGRESS_INTERVAL: Duration = Duration::from_millis(250);

fn main() {
    if let Err(e) = run() {
        eprintln!("Error: {e}");
        std::process::exit(1);
    }
}

fn run() -> Result<(), Box<dyn std::error::Error>> {
    let mut seeds = Vec::new();
    let mut output = None;
    let mut url = None;
    let mut args = std::env::args().skip(1);
    while let Some(arg) = args.next() {
        match arg.as_str() {
            "-i" => seeds.push(PathBuf::from(args.next().ok_or("-i needs a file")?)),
            "-o" => output = Some(PathBuf::from(args.next().ok_or("-o needs a file")?)),
            _ if url.is_none() => url = Some(arg),
            _ => return Err(format!("unexpected argument: {arg}").into()),
        }
    }
    let url = url.ok_or("usage: zsync-rs [-i seed]... -o output url")?;
    let output = output.ok_or("missing -o output")?;

    let mut assembly = ZsyncAssembly::from_url(&url, &output)?;
    for seed in &seeds {
        if let Err(e) = assembly.submit_source_file(seed) {
            eprintln!("Warning: failed to read {}: {e}", seed.display());
        }
    }
    if !seeds.is_empty() && !assembly.is_complete() {
        if let Err(e) = assembly.submit_self_referential() {
            eprintln!("Warning: self-referential scan failed: {e}");
        }
    }

    let (done, total) = assembly.progress();
    println!("progress {done} {total}");
    let last = Mutex::new(Instant::now());
    assembly.set_progress_callback(move |done, total| {
        let mut last = last.lock().unwrap();
        if done < total && last.elapsed() < PROGRESS_INTERVAL {
            return;
        }
        *last = Instant::now();
        println!("progress {done} {total}");
    });

    while !assembly.is_complete() {
        if assembly.download_missing_blocks()? == 0 {
            break;
        }
    }
    assembly.complete()?;
    Ok(())
}
