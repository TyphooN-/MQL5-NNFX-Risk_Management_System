/**=             SignalSlots.mqh  (TyAlgo Modular Signal Slot System)
 *               Copyright 2023, TyphooN (https://www.marketwizardry.org/)
 *
 * Signal Slot Architecture:
 *   Each indicator role (Baseline, Confirmation, Volume, Exit) is a "slot"
 *   configured via enum dropdown in MT5 Properties. Users can swap indicators
 *   per slot or use CUSTOM_GV to read any GlobalVariable — no code changes needed.
 *
 * Signal Convention:
 *   Directional slots: +1 = buy, -1 = sell, 0 = neutral
 *   Volume slot:       1 = pass (sufficient volume), 0 = filtered out
 *   Custom GV contract: indicator must write +1.0/-1.0/0.0 (directional) or >0 (volume pass)
 *
 * Licence: GNU General Public License v3
 **/
#ifndef _SIGNAL_SLOTS_MQH_
#define _SIGNAL_SLOTS_MQH_
// ── Enums (one per slot role) ────────────────────────────────────────────────
enum ENUM_BASELINE_TYPE
{
   BL_NONE      = 0, // Disabled (always pass)
   BL_KAMA      = 1, // KAMA Baseline
   BL_CUSTOM_GV = 2  // Custom GlobalVariable
};
enum ENUM_CONFIRM_TYPE
{
   CF_NONE      = 0, // Disabled (always pass)
   CF_FISHER    = 1, // Fisher Transform Bias
   CF_MTF_MA    = 2, // MTF MA Bull/Bear Power
   CF_CUSTOM_GV = 3  // Custom GlobalVariable
};
enum ENUM_VOLUME_TYPE
{
   VL_NONE        = 0, // Disabled (always pass)
   VL_BETTER_VOL  = 3, // BetterVolume (pass if not Low Volume)
   VL_RVOL        = 1, // Relative Volume (retired)
   VL_CUSTOM_GV   = 2  // Custom GlobalVariable
};
enum ENUM_EXIT_TYPE
{
   EX_NONE      = 0, // Disabled (no exit signal)
   EX_FISHER    = 1, // Fisher Transform Reversal
   EX_CUSTOM_GV = 2  // Custom GlobalVariable
};
// ── Structs ──────────────────────────────────────────────────────────────────
struct SignalResult
{
   int    direction; // +1 buy, -1 sell, 0 neutral (Volume: 1=pass, 0=fail)
   bool   valid;     // false if indicator failed to read
   string label;     // short dashboard text, e.g. "F:+" or "BL:Above"
};
struct SlotState
{
   int    handle;    // iCustom handle (INVALID_HANDLE if GV-based or unused)
   string gvName;    // GlobalVariable name to read
   bool   active;    // true if type != NONE
};
// ── Helpers ──────────────────────────────────────────────────────────────────
bool ReadGlobalVar(string name, double &value)
{
   if (!GlobalVariableGet(name, value)) return false;
   if (!MathIsValidNumber(value)) { value = 0; return false; }
   return true;
}
string GetKAMAGlobalName(ENUM_TIMEFRAMES tf)
{
   string tfStr;
   switch (tf)
   {
      case PERIOD_M1:  tfStr = "M1";  break;
      case PERIOD_M5:  tfStr = "M5";  break;
      case PERIOD_M15: tfStr = "M15"; break;
      case PERIOD_M30: tfStr = "M30"; break;
      case PERIOD_H1:  tfStr = "H1";  break;
      case PERIOD_H4:  tfStr = "H4";  break;
      case PERIOD_D1:  tfStr = "D1";  break;
      case PERIOD_W1:  tfStr = "W1";  break;
      case PERIOD_MN1: tfStr = "MN1"; break;
      default:         tfStr = "D1";  break;
   }
   return "IsAbove_KAMA_" + tfStr;
}
// ── Init Functions ───────────────────────────────────────────────────────────
bool InitBaselineSlot(ENUM_BASELINE_TYPE type, ENUM_TIMEFRAMES kamaTF, string customGV, SlotState &state)
{
   state.handle = INVALID_HANDLE;
   state.gvName = "";
   state.active = (type != BL_NONE);
   if (!state.active) return true;
   switch (type)
   {
      case BL_KAMA:
         state.gvName = GetKAMAGlobalName(kamaTF);
         break;
      case BL_CUSTOM_GV:
         if (customGV == "")
         {
            Print("Baseline CUSTOM_GV: no GlobalVariable name specified");
            return false;
         }
         state.gvName = customGV;
         break;
      default:
         break;
   }
   return true;
}
bool InitConfirmSlot(ENUM_CONFIRM_TYPE type, string customGV, SlotState &state)
{
   state.handle = INVALID_HANDLE;
   state.gvName = "";
   state.active = (type != CF_NONE);
   if (!state.active) return true;
   switch (type)
   {
      case CF_FISHER:
         state.gvName = "FisherBias";
         break;
      case CF_MTF_MA:
         // MTF MA reads two GVs (GlobalBullPowerHTF / GlobalBearPowerHTF) directly in Read
         break;
      case CF_CUSTOM_GV:
         if (customGV == "")
         {
            Print("Confirmation CUSTOM_GV: no GlobalVariable name specified");
            return false;
         }
         state.gvName = customGV;
         break;
      default:
         break;
   }
   return true;
}
bool InitVolumeSlot(ENUM_VOLUME_TYPE type, int rvolDays, string customGV, SlotState &state)
{
   state.handle = INVALID_HANDLE;
   state.gvName = "";
   state.active = (type != VL_NONE);
   if (!state.active) return true;
   switch (type)
   {
      case VL_BETTER_VOL:
         state.handle = iCustom(_Symbol, PERIOD_CURRENT, "BetterVolume");
         if (state.handle == INVALID_HANDLE)
         {
            Print("Failed to create BetterVolume indicator handle: ", GetLastError());
            return false;
         }
         break;
      case VL_RVOL:
         state.handle = iCustom(_Symbol, PERIOD_CURRENT, "RVOL", rvolDays, VOLUME_TICK);
         if (state.handle == INVALID_HANDLE)
         {
            Print("Failed to create RVOL indicator handle: ", GetLastError());
            return false;
         }
         break;
      case VL_CUSTOM_GV:
         if (customGV == "")
         {
            Print("Volume CUSTOM_GV: no GlobalVariable name specified");
            return false;
         }
         state.gvName = customGV;
         break;
      default:
         break;
   }
   return true;
}
bool InitExitSlot(ENUM_EXIT_TYPE type, string customGV, SlotState &state)
{
   state.handle = INVALID_HANDLE;
   state.gvName = "";
   state.active = (type != EX_NONE);
   if (!state.active) return true;
   switch (type)
   {
      case EX_FISHER:
         state.gvName = "FisherBias";
         break;
      case EX_CUSTOM_GV:
         if (customGV == "")
         {
            Print("Exit CUSTOM_GV: no GlobalVariable name specified");
            return false;
         }
         state.gvName = customGV;
         break;
      default:
         break;
   }
   return true;
}
// ── Read Functions ───────────────────────────────────────────────────────────
SignalResult ReadBaselineSignal(ENUM_BASELINE_TYPE type, SlotState &state)
{
   SignalResult r;
   r.direction = 0;
   r.valid = true;
   r.label = "";
   if (!state.active) return r;
   switch (type)
   {
      case BL_KAMA:
      {
         double val = -1;
         if (!ReadGlobalVar(state.gvName, val))
         {
            r.valid = false;
            r.label = "BL:Err";
            return r;
         }
         if (val > 0.5)
            r.direction = +1;
         else if (val < 0.5)
            r.direction = -1;
         else
            r.direction = 0;
         r.label = "BL:" + (r.direction > 0 ? "Above" : (r.direction < 0 ? "Below" : "?"));
         break;
      }
      case BL_CUSTOM_GV:
      {
         double val = 0;
         if (!ReadGlobalVar(state.gvName, val))
         {
            r.valid = false;
            r.label = "BL:Err";
            return r;
         }
         if (val > 0) r.direction = +1;
         else if (val < 0) r.direction = -1;
         else r.direction = 0;
         r.label = "BL:" + (r.direction > 0 ? "+" : (r.direction < 0 ? "-" : "0"));
         break;
      }
      default:
         break;
   }
   return r;
}
SignalResult ReadConfirmSignal(ENUM_CONFIRM_TYPE type, SlotState &state, double minBullHTF, double minBearHTF)
{
   SignalResult r;
   r.direction = 0;
   r.valid = true;
   r.label = "";
   if (!state.active) return r;
   switch (type)
   {
      case CF_FISHER:
      {
         double val = 0;
         if (!ReadGlobalVar(state.gvName, val))
         {
            r.valid = false;
            r.label = "F:Err";
            return r;
         }
         if (val > 0) r.direction = +1;
         else if (val < 0) r.direction = -1;
         else r.direction = 0;
         r.label = "F:" + (r.direction > 0 ? "+" : (r.direction < 0 ? "-" : "0"));
         break;
      }
      case CF_MTF_MA:
      {
         double bullPower = 0, bearPower = 0;
         if (!ReadGlobalVar("GlobalBullPowerHTF", bullPower) || !ReadGlobalVar("GlobalBearPowerHTF", bearPower))
         {
            r.valid = false;
            r.label = "M:Err";
            return r;
         }
         // Buy if bull power meets threshold, sell if bear power meets threshold
         bool bullOK = bullPower >= minBullHTF;
         bool bearOK = bearPower >= minBearHTF;
         if (bullOK && !bearOK)
            r.direction = +1;
         else if (bearOK && !bullOK)
            r.direction = -1;
         else if (bullOK && bearOK)
            r.direction = 0; // Conflicting — neutral
         else
            r.direction = 0; // Neither meets threshold
         r.label = "M:" + DoubleToString(bullPower, 0) + "/" + DoubleToString(bearPower, 0);
         break;
      }
      case CF_CUSTOM_GV:
      {
         double val = 0;
         if (!ReadGlobalVar(state.gvName, val))
         {
            r.valid = false;
            r.label = "C:Err";
            return r;
         }
         if (val > 0) r.direction = +1;
         else if (val < 0) r.direction = -1;
         else r.direction = 0;
         r.label = "C:" + (r.direction > 0 ? "+" : (r.direction < 0 ? "-" : "0"));
         break;
      }
      default:
         break;
   }
   return r;
}
SignalResult ReadVolumeSignal(ENUM_VOLUME_TYPE type, SlotState &state, double minRVOL)
{
   SignalResult r;
   r.direction = 1; // Default pass when inactive
   r.valid = true;
   r.label = "";
   if (!state.active) return r;
   switch (type)
   {
      case VL_BETTER_VOL:
      {
         // Buffer 1 = color index: 0=LowVol, 1=ClimaxUp, 2=ClimaxDn, 3=Churn, 4=ClimaxChurn, 5=Normal
         double colorBuf[];
         if (CopyBuffer(state.handle, 1, 1, 1, colorBuf) != 1)
         {
            r.valid = false;
            r.direction = 0;
            r.label = "V:Err";
            return r;
         }
         int cls = (int)colorBuf[0];
         // VOL_LOW = 0 → fail; everything else → pass
         r.direction = (cls != 0) ? 1 : 0;
         string labels[] = {"Low","ClxUp","ClxDn","Churn","Clx+Ch","Norm"};
         r.label = "V:" + ((cls >= 0 && cls <= 5) ? labels[cls] : "?");
         break;
      }
      case VL_RVOL:
      {
         double rvolBuffer[];
         if (CopyBuffer(state.handle, 0, 1, 1, rvolBuffer) != 1)
         {
            r.valid = false;
            r.direction = 0;
            r.label = "R:Err";
            return r;
         }
         double rval = rvolBuffer[0];
         r.direction = (rval >= minRVOL) ? 1 : 0;
         r.label = "R:" + DoubleToString(rval, 2);
         break;
      }
      case VL_CUSTOM_GV:
      {
         double val = 0;
         if (!ReadGlobalVar(state.gvName, val))
         {
            r.valid = false;
            r.direction = 0;
            r.label = "R:Err";
            return r;
         }
         r.direction = (val > 0) ? 1 : 0;
         r.label = "R:" + (r.direction == 1 ? "Pass" : "Fail");
         break;
      }
      default:
         break;
   }
   return r;
}
SignalResult ReadExitSignal(ENUM_EXIT_TYPE type, SlotState &state)
{
   SignalResult r;
   r.direction = 0;
   r.valid = true;
   r.label = "";
   if (!state.active) return r;
   double val = 0;
   if (!ReadGlobalVar(state.gvName, val))
   {
      r.valid = false;
      r.label = "X:Err";
      return r;
   }
   if (val > 0) r.direction = +1;
   else if (val < 0) r.direction = -1;
   else r.direction = 0;
   r.label = "X:" + (r.direction > 0 ? "+" : (r.direction < 0 ? "-" : "0"));
   return r;
}
// ── Cleanup ──────────────────────────────────────────────────────────────────
void DeinitSlot(SlotState &state)
{
   if (state.handle != INVALID_HANDLE)
   {
      IndicatorRelease(state.handle);
      state.handle = INVALID_HANDLE;
   }
   state.active = false;
}
#endif // _SIGNAL_SLOTS_MQH_
