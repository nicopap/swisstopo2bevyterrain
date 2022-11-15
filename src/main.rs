use std::error::Error;
use std::fs::File;
use std::io::{BufReader, BufWriter, Read, Seek};
use std::path::PathBuf;

use clap::{Parser, Subcommand};
use image::{ImageBuffer, ImageFormat, Luma};
use tiff::decoder::{Decoder, DecodingResult};

const MAX_SWISS_HEIGHT: f32 = 4644.0;
const MIN_SWISS_HEIGHT: f32 = 193.0;
const SWISS_HEIGHT_TO_U16: f32 = (MAX_SWISS_HEIGHT - MIN_SWISS_HEIGHT) / u16::MAX as f32;
fn swiss_f32_to_u16(height: f32) -> u16 {
    ((height - MIN_SWISS_HEIGHT) / SWISS_HEIGHT_TO_U16) as u16
}

#[derive(Parser, Debug)]
struct Cli {
    #[command(subcommand)]
    kind: TiffKind,
    #[arg(short, long, value_name = "INPUT FILE")]
    input: PathBuf,
    #[arg(short, long, value_name = "OUTPUT FILE")]
    output: PathBuf,
}
#[derive(Subcommand, Clone, Copy, Debug)]
enum TiffKind {
    Topo,
    Albedo,
}

fn read_32f_tiff(reader: impl Read + Seek) -> (Vec<f32>, u32, u32) {
    let mut decoder = Decoder::new(reader).unwrap();
    let (width, height) = decoder.dimensions().unwrap();
    if let DecodingResult::F32(buffer) = decoder.read_image().unwrap() {
        (buffer, width, height)
    } else {
        panic!("Not f32!")
    }
}
fn main() -> Result<(), Box<dyn Error>> {
    let cli = Cli::parse();
    let input = BufReader::new(File::open(cli.input)?);
    let mut output = BufWriter::new(File::create(cli.output)?);
    match cli.kind {
        TiffKind::Topo => {
            let (f32_buffer, width, height) = read_32f_tiff(input);
            let u16_buffer: Vec<_> = f32_buffer.into_iter().map(swiss_f32_to_u16).collect();
            let image: ImageBuffer<Luma<u16>, _> = ImageBuffer::from_raw(width, height, u16_buffer)
                .ok_or::<Box<dyn Error>>("Bad image".into())?;
            image.write_to(&mut output, ImageFormat::Png)?;
        }
        TiffKind::Albedo => {
            let rgba_buffer = image::io::Reader::with_format(input, ImageFormat::Tiff).decode()?;
            let rgb_buffer = rgba_buffer.into_rgb8();
            rgb_buffer.write_to(&mut output, ImageFormat::Png)?;
        }
    }
    Ok(())
    // read_img("test.tif");
    // read_img("swissimage-dop10_2021_2640-1153_2_2056.tif");
    // read_img("swissalti3d_2019_2640-1153_2_2056_5728.tif");
}
