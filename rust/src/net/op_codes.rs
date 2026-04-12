// AUTO-GENERATED NETWORK OP CODES
// Do not edit manually. Run registry_builder.gd in Godot.

#[repr(u16)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum OpCode {
    AuthRequest = 11063,
    AuthSuccess = 38012,
    StateSync = 17737,
    InputTick = 54449,
    CastSkill = 59788,
    CancelSkill = 20576,
    SendChat = 53360,
    ChatMessage = 51365,
    PickupItem = 30140,
    BuryItem = 37904,
}

impl TryFrom<u16> for OpCode {
    type Error = ();
    fn try_from(v: u16) -> Result<Self, Self::Error> {
        match v {
            11063 => Ok(OpCode::AuthRequest),
            38012 => Ok(OpCode::AuthSuccess),
            17737 => Ok(OpCode::StateSync),
            54449 => Ok(OpCode::InputTick),
            59788 => Ok(OpCode::CastSkill),
            20576 => Ok(OpCode::CancelSkill),
            53360 => Ok(OpCode::SendChat),
            51365 => Ok(OpCode::ChatMessage),
            30140 => Ok(OpCode::PickupItem),
            37904 => Ok(OpCode::BuryItem),
            _ => Err(()),
        }
    }
}
