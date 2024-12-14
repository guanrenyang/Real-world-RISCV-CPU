package ysyx

import chisel3._
import chisel3.util._

class bitrev extends BlackBox {
  val io = IO(Flipped(new SPIIO(1)))
}

class bitrevChisel extends RawModule { // we do not need clock and reset
  val io = IO(Flipped(new SPIIO(1)))

  withClock(io.sck.asClock){
    val bitrev_buff=Reg(Vec(8,UInt(1.W))) 
    val bit_cnt=Reg(UInt(4.W))

    when(!io.ss){
      bit_cnt:=bit_cnt+1.U
      when(bit_cnt<8.U){        
        io.miso:=false.B
        bitrev_buff(bit_cnt(2,0)):=io.mosi
      }otherwise{
        io.miso:=bitrev_buff(7.U-bit_cnt(2,0))
      }
    }.otherwise{
      bitrev_buff:=0.U.asTypeOf(bitrev_buff)
      bit_cnt:=0.U
      io.miso:=true.B
    }
  }
}
