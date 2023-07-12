# MQL5-Risk_Management_System
TyphooN's MQL5-Risk_Management_System (Expert)

### Features
-Simple trade management via SL, TP, and Limit lines places on the chart.

-Open trade button to execute a position or order.

-Limit Line places a Limit line (White) on the chart, and will place a limit order when this line is present on the chart rather than market execution.

-Buy Lines places TP (Green) and SL (Red) lines on the chart for a buy position.

-Sell Lines places TP (Green) and SL (Red) lines on the chart for a sell position.

-Destroy Lines removes all expert placed horizontal lines from the chart.

-EnableAutoProtect will place stop loss at break even when RR passes AutoProtectRRLevel and risk > 0.

-Protect button sets stop loss to break even.

-Close Positions Button orders to close all orders on the active chart symbol.

-Close Limits button to close all limit orders.

-Set TP modifies existing position TP level to the price that the TP (Green) line is currently at.

-Set SL modifies existing position SL level to the price that the SL (Red) line is currently at.

-Displays Total P/L, Risk, Total profit at TP, and RR of the positions on the chart.

-Has been tested extensively on FTMO and Eightcap brokers.  YMMV on other brokers.

### User Vars
-Risk (set to % risk per position or limit order).

-EnableAutoProtect will place stop loss at break even when RR passes AutoProtectRRLevel and risk > 0.

-AutoProtectRRLevel is the Reward:Risk level that will automatically move stop loss to break even using EnableAutoProtect.

-MagicNumber (can be set to anything the user wants, but this expert will only modify trades/positions that match the MagicNumber on the chart).

-TPPips and SLPips (will change where the TP and SL line appear on the chart).

-HorizontalLineThickness - how thick SL, TP, and Limit lines are on the chart.

### Usage

This project is intended and may be freely used for education and entertainment purposes.
However, **this project is not suitable for live trading** without relevant knowledge.

### License

The project is released under [GNU GPLv3 licence](https://www.gnu.org/licenses/quick-guide-gplv3.html),
so that means the software is copyrighted, however you have the freedom to use, change or share the software
for any purpose as long as the modified version stays free. See: [GNU FAQ](https://www.gnu.org/licenses/gpl-faq.html).

You should have received a copy of the GNU General Public License along with this program
(check the [LICENSE] file).
If not, please read <http://www.gnu.org/licenses/>.
For simplified version, please read <https://tldrlegal.com/license/gnu-general-public-license-v3-(gpl-3)>.

## Terms of Use

By using this software, you understand and agree that we (company and author)
are not be liable or responsible for any loss or damage due to any reason.
Although every attempt has been made to assure accuracy,
we do not give any express or implied warranty as to its accuracy.
We do not accept any liability for error or omission.

You acknowledge that you are familiar with these risks
and that you are solely responsible for the outcomes of your decisions.
We accept no liability whatsoever for any direct or consequential loss arising from the use of this product.
You understand and agree that past results are not necessarily indicative of future performance.

Use of this software serves as your acknowledgement and representation that you have read and understand
these TERMS OF USE and that you agree to be bound by such Terms of Use ("License Agreement").

### Copyright information

Copyright © 2023 - Decapool.net - All Rights Reserved

### Disclaimer and Risk Warnings

Trading any financial market involves risk.
All forms of trading carry a high level of risk so you should only speculate with money you can afford to lose.
You can lose more than your initial deposit and stake.
Please ensure your chosen method matches your investment objectives,
familiarize yourself with the risks involved and if necessary seek independent advice.

NFA and CTFC Required Disclaimers:
Trading in the Foreign Exchange market as well as in Futures Market and Options or in the Stock Market
is a challenging opportunity where above average returns are available for educated and experienced investors
who are willing to take above average risk.
However, before deciding to participate in Foreign Exchange (FX) trading or in Trading Futures, Options or stocks,
you should carefully consider your investment objectives, level of experience and risk appetite.
**Do not invest money you cannot afford to lose**.

CFTC RULE 4.41 - HYPOTHETICAL OR SIMULATED PERFORMANCE RESULTS HAVE CERTAIN LIMITATIONS.
UNLIKE AN ACTUAL PERFORMANCE RECORD, SIMULATED RESULTS DO NOT REPRESENT ACTUAL TRADING.
ALSO, SINCE THE TRADES HAVE NOT BEEN EXECUTED, THE RESULTS MAY HAVE UNDER-OR-OVER COMPENSATED FOR THE IMPACT,
IF ANY, OF CERTAIN MARKET FACTORS, SUCH AS LACK OF LIQUIDITY. SIMULATED TRADING PROGRAMS IN GENERAL
ARE ALSO SUBJECT TO THE FACT THAT THEY ARE DESIGNED WITH THE BENEFIT OF HINDSIGHT.
NO REPRESENTATION IS BEING MADE THAN ANY ACCOUNT WILL OR IS LIKELY TO ACHIEVE PROFIT OR LOSSES SIMILAR TO THOSE SHOWN.
