package ysyx

import chisel3._
import chisel3.util._

class bitrev extends BlackBox {
  val io = IO(Flipped(new SPIIO(1)))
}

class bitrevChisel extends RawModule { // We do not need implicit clock and reset
  val io = IO(Flipped(new SPIIO(1)))

  // Convert io.sck into a clock signal
  val sckClock = io.sck.asClock
  // Since we are using RawModule, we can define our reset if needed
  val asyncReset = false.B.asAsyncReset // Using a constant false as reset

  // Default assignment for io.miso
  io.miso := true.B

  // Define registers with the custom clock (io.sck)
  withClockAndReset(sckClock, asyncReset) {
    val dataIn     = RegInit(0.U(8.W))
    val bitCounter = RegInit(0.U(3.W))
    val state      = RegInit(0.U(2.W)) // 0: idle, 1: receiving, 2: sending

    when(!io.ss) { // Active low slave select
      switch(state) {
        is(0.U) {
          // Receiving data
          dataIn     := Cat(dataIn(6, 0), io.mosi)
          bitCounter := bitCounter + 1.U
          when(bitCounter === 7.U) {
            state      := 1.U
            bitCounter := 0.U
          }
        }
        is(1.U) {
          // Transition to sending state
          state := 2.U
          // Reverse the received data
          // dataIn := dataIn.asUInt().reverse
        }
        is(2.U) {
          // Sending data
          io.miso    := dataIn(bitCounter)
          bitCounter := bitCounter + 1.U
          when(bitCounter === 7.U) {
            state      := 0.U
            bitCounter := 0.U
          }
        }
      }
    } .otherwise {
      // Reset state when not selected
      state      := 0.U
      bitCounter := 0.U
      // io.miso remains true.B due to default assignment
    }
  }
}
