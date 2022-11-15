use image::{ImageBuffer, Rgb};

fn main() {
    let img_file = File::open("swissimage-dop10_2021_2640-1153_2_2056.tif").unwrap();
    let mut decoder = Decoder::new(img_file).unwrap();
    println!("{:?}", decoder.read_image().map(|t| {
        if let DecodingResult::
    }));
    let img_file = File::open("swissalti3d_2019_2640-1153_2_2056_5728.tif").unwrap();
    let mut decoder = Decoder::new(img_file).unwrap();
    println!("{:?}", decoder.read_image().map(|t| t.len()));
}
