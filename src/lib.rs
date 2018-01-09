#![no_std]
#![feature(lang_items)]

pub mod panic;

pub extern "C" fn kernel_main(){
    loop {} 
}

