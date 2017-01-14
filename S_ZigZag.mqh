//+------------------------------------------------------------------+
//|                 EA31337 - multi-strategy advanced trading robot. |
//|                       Copyright 2016-2017, 31337 Investments Ltd |
//|                                       https://github.com/EA31337 |
//+------------------------------------------------------------------+

/*
   This file is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

// Properties.
#property strict

/**
 * @file
 * Implementation of ATR Strategy based on the Average True Range indicator (ATR).
 *
 * @docs
 * - https://www.mql5.com/en/code/7796
 */

// Includes.
#include <EA31337-classes\Strategy.mqh>
#include <EA31337-classes\Strategies.mqh>

// User inputs.
#ifdef __input__ input #endif string __ZigZag_Parameters__ = "-- Settings for the ZigZag indicator --"; // >>> ZIGZAG <<<
#ifdef __input__ input #endif double ZigZag_SignalLevel = 0.00000000; // Signal level
#ifdef __input__ input #endif int ZigZag_SignalMethod = 0; // Signal method for M1 (0-31)

#define ZZ_BUFFERS  1
#define ZZ_VALUES   3

#define ZZ_NAME_MT4 "ZigZag"
#define ZZ_NAME_MT5 "Examples\\ZigZag"
//+------------------------------------------------------------------+
//|   CMovingTrade                                                   |
//+------------------------------------------------------------------+
class CZigZagTrade : public CBasicTrade {
  private:
    int               m_handles[TFS];
    string            m_symbol;

    int               m_depth;
    int               m_deviation;
    int               m_backstep;

    double            m_val[ZZ_BUFFERS][TFS][ZZ_VALUES];
    int               m_last_error;

    //+------------------------------------------------------------------+
    bool  Update(const ENUM_TIMEFRAMES _tf=PERIOD_CURRENT)
    {
      int index=TimeframeToIndex(_tf);

#ifdef __MQL4__     
      for(int i=0;i<ZZ_BUFFERS;i++)
        for(int k=0;k<ZZ_VALUES;k++)
          m_val[i][index][k] = GetZigZagPeak(NULL,
              _tf,
              m_depth,
              m_deviation,
              m_backstep,
              i,
              k);
      );                                       
      return(true);
#endif

#ifdef __MQL5__
      double array[];

      for(int i=0;i<ZZ_VALUES;i++)
        m_val[0][index][i]=GetZigZagPeak(NULL, _tf, m_handles[index], i);

      // test 
      //Comment("CUR: ", m_val[0][index][CUR], " PREV: ", m_val[0][index][PREV], " FAR: ", m_val[0][index][FAR]);

      return(true);
#endif

      return(false);
    }
  public:

    //+------------------------------------------------------------------+
    void  CZigZagTrade()
    {
      m_symbol=_Symbol;
      m_depth=14;
      m_deviation=3;
      m_backstep=3;
      m_last_error=0;
      ArrayInitialize(m_handles,INVALID_HANDLE);
    }

    //+------------------------------------------------------------------+
    bool  SetParams(const string symbol,
        const int depth,
        const int deviation,
        const int backstep)
    {
      m_symbol=symbol;
      m_depth=fmax(1,depth);
      m_deviation=fmax(1,deviation);
      m_backstep=fmax(1,backstep);

#ifdef __MQL5__
      for(int i=0;i<TFS;i++)
      {
        m_handles[i]=iCustom(m_symbol,
            tf[i],
            ZZ_NAME_MT5,
            m_depth,
            m_deviation,
            m_backstep);
        if(m_handles[i]==INVALID_HANDLE)
          return(false);
      }
#endif
      return(true);
    }

/*
bool Trade_ZigZag(int cmd, ENUM_TIMEFRAMES tf = PERIOD_M1, int signal_method = EMPTY, double signal_level = EMPTY) {
  bool result = FALSE; int period = Timeframe::TfToIndex(tf);
  UpdateIndicator(S_ZIGZAG, tf);
  if (signal_method == EMPTY) signal_method = GetStrategySignalMethod(S_ZIGZAG, tf, 0);
  if (signal_level  == EMPTY) signal_level  = GetStrategySignalLevel(S_ZIGZAG, tf, 0.0);
  switch (cmd) {
    case OP_BUY:
      /*
        bool result = ZigZag[period][CURR][LOWER] != 0.0 || ZigZag[period][PREV][LOWER] != 0.0 || ZigZag[period][FAR][LOWER] != 0.0;
        if ((signal_method &   1) != 0) result &= Open[CURR] > Close[CURR];
        if ((signal_method &   2) != 0) result &= !ZigZag_On_Sell(tf);
        if ((signal_method &   4) != 0) result &= ZigZag_On_Buy(fmin(period + 1, M30));
        if ((signal_method &   8) != 0) result &= ZigZag_On_Buy(M30);
        if ((signal_method &  16) != 0) result &= ZigZag[period][FAR][LOWER] != 0.0;
        if ((signal_method &  32) != 0) result &= !ZigZag_On_Sell(M30);
        */
    break;
    case OP_SELL:
      /*
        bool result = ZigZag[period][CURR][UPPER] != 0.0 || ZigZag[period][PREV][UPPER] != 0.0 || ZigZag[period][FAR][UPPER] != 0.0;
        if ((signal_method &   1) != 0) result &= Open[CURR] < Close[CURR];
        if ((signal_method &   2) != 0) result &= !ZigZag_On_Buy(tf);
        if ((signal_method &   4) != 0) result &= ZigZag_On_Sell(fmin(period + 1, M30));
        if ((signal_method &   8) != 0) result &= ZigZag_On_Sell(M30);
        if ((signal_method &  16) != 0) result &= ZigZag[period][FAR][UPPER] != 0.0;
        if ((signal_method &  32) != 0) result &= !ZigZag_On_Buy(M30);
        */
    break;
  }
  return result;
}
*/

  /**
   * Check if ZigZag indicator is on buy or sell.
   *
   * @param
   *   cmd (int) - type of trade order command
   *   period (int) - period to check for
   *   signal_method (int) - signal method to use by using bitwise AND operation
   *   signal_level (double) - signal level to consider the signal
   */
  bool  Signal(const ENUM_TRADE_DIRECTION _cmd,const ENUM_TIMEFRAMES _tf,int _open_method,const int open_level) {

      if(!Update(_tf))
        return(false);

      //--- detect 'one of methods'
      bool one_of_methods=false;
      if(_open_method<0)
        one_of_methods=true;
      _open_method=fabs(_open_method);

      //---
      int index=TimeframeToIndex(_tf);
      double level=open_level*_Point;

      //---
      int result[OPEN_METHODS];
      ArrayInitialize(result,-1);

      for(int i=0; i<OPEN_METHODS; i++)
      {
        //---
        if(_cmd==TRADE_BUY)
        {
          switch(_open_method&(int)pow(2,i))
          {
            case OPEN_METHOD1: result[i]=m_val[0][index][CUR] > m_val[0][index][PREV]; break;
            case OPEN_METHOD2: result[i]=SymbolInfoDouble(Symbol(),SYMBOL_ASK) > m_val[0][index][PREV]; break;
            case OPEN_METHOD3: result[i]=false; break;
            case OPEN_METHOD4: result[i]=false; break;
            case OPEN_METHOD5: result[i]=false; break;
            case OPEN_METHOD6: result[i]=false; break;
            case OPEN_METHOD7: result[i]=false; break;
            case OPEN_METHOD8: result[i]=false; break;
          }
        }

        //---
        if(_cmd==TRADE_SELL)
        {
          switch(_open_method&(int)pow(2,i))
          {
            case OPEN_METHOD1: result[i]=m_val[0][index][CUR] < m_val[0][index][PREV]; break;
            case OPEN_METHOD2: result[i]=SymbolInfoDouble(Symbol(),SYMBOL_BID) < m_val[0][index][PREV]; break;
            case OPEN_METHOD3: result[i]=false; break;
            case OPEN_METHOD4: result[i]=false; break;
            case OPEN_METHOD5: result[i]=false; break;
            case OPEN_METHOD6: result[i]=false; break;
            case OPEN_METHOD7: result[i]=false; break;
            case OPEN_METHOD8: result[i]=false; break;
          }
        }
      }

      //--- calc result
      bool res_value=false;
      for(int i=0; i<OPEN_METHODS; i++)
      {
        //--- true
        if(result[i]==1)
        {
          res_value=true;

          //--- OR logic
          if(one_of_methods)
            break;
        }
        //--- false
        if(result[i]==0)
        {
          res_value=false;

          //--- AND logic
          if(!one_of_methods)
            break;
        }
      }
      //--- done
      return(res_value);
  }

#ifdef __MQL5__
    double GetZigZagPeak(string _sym, ENUM_TIMEFRAMES _tf_, int zz_handle, int _extrm){
      double _zz[];
      int  k, ke = 0;  

      if (_sym == NULL)
        _sym = Symbol(); 

      k = Bars(_sym, _tf_);

      for(int i=0; i<k; i++) {
        CopyBuffer(zz_handle, 0, i, 1, _zz);

        if(_zz[0] != 0) {
          ke++;
          if(ke > _extrm) return(_zz[0]);
        }
      }
      Print("Error in GetZigZagPeak()");
      return(-1);
#endif 

#ifdef __MQL4__
      double GetZigZagPeak(string _sym, ENUM_TIMEFRAMES _tf_, int _dpth, int _dvt, int _bckstp, int _bff, int _extrm)
      {
        double buffer;
        int count = 0;

        if (_sym == NULL)
          _sym = Symbol();

        for (int i = 0; i < iBars(_sym, _tf_) - 1; i++)
        {
          buffer = iCustom(_sym, _tf_, ZZ_NAME_MT4, _dpth, _dvt, _bckstp, _bff, i);

          if (buffer != 0)
          {
            count++;
            if (count > _extrm)
            {				
              return (buffer);
            }
          }
        }
        Print("Error in GetZigZagPeak()");
        return (-1);
      }
#endif 

    }
};