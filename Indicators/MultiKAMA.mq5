/**=             MultiKAMA.mq5  (TyphooN's MultiKAMA)
 *               Copyright 2023, TyphooN (https://www.marketwizardry.org/)
 *
 * Disclaimer and Licence
 *
 * This file is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * All trading involves risk. You should have received the risk warnings
 * and terms of use in the README.MD file distributed with this software.
 * See the README.MD file for more information and before using this software.
 *
 **/
#property copyright   "Copyright 2023 TyphooN (MarketWizardry.org)"
#property link        "https://www.marketwizardry.info"
#property version     "1.008"
#property description "Multi-Timeframe Kaufman's Adaptive Moving Average"
#property indicator_chart_window
#property indicator_buffers 5
#property indicator_plots   5
#property indicator_label1  "KAMA_H1"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrWhite
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2
#property indicator_label2  "KAMA_H4"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrWhite
#property indicator_style2  STYLE_SOLID
#property indicator_width2  2
#property indicator_label3  "KAMA_D1"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrWhite
#property indicator_style3  STYLE_SOLID
#property indicator_width3  2
#property indicator_label4  "KAMA_W1"
#property indicator_type4   DRAW_LINE
#property indicator_color4  clrWhite
#property indicator_style4  STYLE_SOLID
#property indicator_width4  2
#property indicator_label5  "KAMA_MN1"
#property indicator_type5   DRAW_LINE
#property indicator_color5  clrWhite
#property indicator_style5  STYLE_SOLID
#property indicator_width5  2

#include "MultiKAMA.mqh"
