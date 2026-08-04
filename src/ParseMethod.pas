{ ************************************************************************** }
{                                                                            }
{ ParseMethod                                                                }
{                                                                            }
{ Copyright © 2006 Yuriy Pisarev (ypisareff@outlook.com)                     }
{                                                                            }
{ ************************************************************************** }

unit ParseMethod;

{$B-}
{$I Directives.inc}
{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  {$IFDEF FPC}
  SysUtils, FlexibleList, ParseTypes, Types, ValueTypes;
  {$ELSE}
  {$IFDEF DELPHI_XE7}
  WinApi.Windows, System.SysUtils, BaseTypes, FlexibleList, ParseTypes, Types,
  ValueTypes;
  {$ELSE}
  Windows, SysUtils, FlexibleList, ParseTypes, Types, ValueTypes;
  {$ENDIF}
  {$ENDIF}

type
  TVariableContainer = class
  private
    FList: TFlexibleList;
  protected
    function Find(const Name: string;
      Index: {$IFDEF FPC}System.{$ENDIF}PInteger = nil): Boolean; virtual;
    property List: TFlexibleList read FList write FList;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    procedure SetVariable(const Name: string; const Value: PValue); virtual;
    function Delete(const Name: string): Boolean; overload; virtual;
    procedure Clear; virtual;
  end;

  TCustomMethod = class
  private
    FParser: TObject;
  public
    constructor Create(const AParser: TObject); virtual;
    property Parser: TObject read FParser write FParser;
  end;

  TMethod = class(TCustomMethod)
  private
    FContainer: TVariableContainer;
  protected
    property Container: TVariableContainer read FContainer write FContainer;
  public
    constructor Create(const AParser: TObject); override;
    destructor Destroy; override;
    function VoidMethod(const Header: PScriptHeader; const AFunction: PFunction;
      const AType: PType): TValue; virtual;
    function NewMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const PA: TParameterArray): TValue; virtual;
    function DeleteMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const PA: TParameterArray): TValue; virtual;
    function FindMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const PA: TParameterArray): TValue; virtual;
    function GetMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const PA: TParameterArray): TValue; virtual;
    function SetMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const PA: TParameterArray): TValue; virtual;
    function ScriptMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const PA: TParameterArray): TValue; virtual;
    function ExecuteMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const PA: TParameterArray): TValue; virtual;
    function ExitMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const PA: TParameterArray): TValue; virtual;
    function ForMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const PA: TParameterArray): TValue; virtual;
    function RepeatMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const PA: TParameterArray): TValue; virtual;
    function WhileMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const PA: TParameterArray): TValue; virtual;
    function MultiplyMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const LValue, RValue: TValue): TValue; virtual;
    function DivideMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const LValue, RValue: TValue): TValue; virtual;
    function SuccMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const Value: TValue): TValue; virtual;
    function PredMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const Value: TValue): TValue; virtual;
    function NotMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const Value: TValue): TValue; virtual;
    function AndMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const LValue, RValue: TValue): TValue; virtual;
    function OrMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const LValue, RValue: TValue): TValue; virtual;
    function XorMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const LValue, RValue: TValue): TValue; virtual;
    function ShlMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const LValue, RValue: TValue): TValue; virtual;
    function ShrMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const LValue, RValue: TValue): TValue; virtual;
    function TryFinallyMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const PA: TParameterArray): TValue; virtual;
    function TryExceptMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const PA: TParameterArray): TValue; virtual;
    function SameValueMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const PA: TParameterArray): TValue; virtual;
    function IsZeroMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const PA: TParameterArray): TValue; virtual;
    function IfMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const PA: TParameterArray): TValue; virtual;
    function IfThenMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const PA: TParameterArray): TValue; virtual;
    function EnsureRangeMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const PA: TParameterArray): TValue; virtual;
    function StrToIntMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const PA: TParameterArray): TValue; virtual;
    function StrToIntDefMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const PA: TParameterArray): TValue; virtual;
    function StrToFloatMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const PA: TParameterArray): TValue; virtual;
    function StrToFloatDefMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const PA: TParameterArray): TValue; virtual;
    function ParseMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const PA: TParameterArray): TValue; virtual;
    function DerivMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const PA: TParameterArray): TValue; virtual;
    function TrueMethod(const Header: PScriptHeader; const AFunction: PFunction;
      const AType: PType): TValue; virtual;
    function FalseMethod(const Header: PScriptHeader; const AFunction: PFunction;
      const AType: PType): TValue; virtual;
    function EqualMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const LValue, RValue: TValue): TValue; virtual;
    function NotEqualMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const LValue, RValue: TValue): TValue; virtual;
    function AboveMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const LValue, RValue: TValue): TValue; virtual;
    function BelowMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const LValue, RValue: TValue): TValue; virtual;
    function AboveOrEqualMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const LValue, RValue: TValue): TValue; virtual;
    function BelowOrEqualMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const LValue, RValue: TValue): TValue; virtual;
    function GetEpsilonMethod(const Header: PScriptHeader; const AFunction: PFunction;
      const AType: PType): TValue; virtual;
    function SetEpsilonMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const PA: TParameterArray): TValue; virtual;
    function SetDecimalSeparatorMethod(const Header: PScriptHeader; const AFunction: PFunction;
      const AType: PType; const PA: TParameterArray): TValue; virtual;
  end;

  TMathMethod = class(TCustomMethod)
  public
    function DivMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const LValue, RValue: TValue): TValue; virtual;
    function ModMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const LValue, RValue: TValue): TValue; virtual;
    function DegreeMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const LValue, RValue: TValue): TValue; virtual;
    function FactorialMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const PA: TParameterArray): TValue; virtual;
    function SqrMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const Value: TValue): TValue; virtual;
    function SqrtMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const Value: TValue): TValue; virtual;
    function IntMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const Value: TValue): TValue; virtual;
    function RoundMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const Value: TValue): TValue; virtual;
    function RoundToMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const PA: TParameterArray): TValue; virtual;
    function TruncMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const Value: TValue): TValue; virtual;
    function AbsMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const Value: TValue): TValue; virtual;
    function FracMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const Value: TValue): TValue; virtual;
    function LnMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const Value: TValue): TValue; virtual;
    function LgMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const Value: TValue): TValue; virtual;
    function LogMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const LValue, RValue: TValue): TValue; virtual;
    function ExpMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const Value: TValue): TValue; virtual;
    function RandomMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const Value: TValue): TValue; virtual;
    function SinMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const Value: TValue): TValue; virtual;
    function ArcSinMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const Value: TValue): TValue; virtual;
    function SinHMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const Value: TValue): TValue; virtual;
    function ArcSinHMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const Value: TValue): TValue; virtual;
    function CosMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const Value: TValue): TValue; virtual;
    function ArcCosMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const Value: TValue): TValue; virtual;
    function CosHMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const Value: TValue): TValue; virtual;
    function ArcCosHMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const Value: TValue): TValue; virtual;
    function TanMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const Value: TValue): TValue; virtual;
    function ArcTanMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const Value: TValue): TValue; virtual;
    function TanHMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const Value: TValue): TValue; virtual;
    function ArcTanHMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const Value: TValue): TValue; virtual;
    function CoTanMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const Value: TValue): TValue; virtual;
    function ArcCoTanMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const Value: TValue): TValue; virtual;
    function CoTanHMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const Value: TValue): TValue; virtual;
    function ArcCoTanHMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const Value: TValue): TValue; virtual;
    function SecMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const Value: TValue): TValue; virtual;
    function ArcSecMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const Value: TValue): TValue; virtual;
    function SecHMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const Value: TValue): TValue; virtual;
    function ArcSecHMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const Value: TValue): TValue; virtual;
    function CscMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const Value: TValue): TValue; virtual;
    function ArcCscMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const Value: TValue): TValue; virtual;
    function CscHMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const Value: TValue): TValue; virtual;
    function ArcCscHMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const Value: TValue): TValue; virtual;
    function ArcTan2Method(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const PA: TParameterArray): TValue; virtual;
    function YearMethod(const Header: PScriptHeader; const AFunction: PFunction;
      const AType: PType): TValue; virtual;
    function MonthMethod(const Header: PScriptHeader; const AFunction: PFunction;
      const AType: PType): TValue; virtual;
    function DayMethod(const Header: PScriptHeader; const AFunction: PFunction;
      const AType: PType): TValue; virtual;
    function DayOfWeekMethod(const Header: PScriptHeader; const AFunction: PFunction;
      const AType: PType): TValue; virtual;
    function HourMethod(const Header: PScriptHeader; const AFunction: PFunction;
      const AType: PType): TValue; virtual;
    function MinuteMethod(const Header: PScriptHeader; const AFunction: PFunction;
      const AType: PType): TValue; virtual;
    function SecondMethod(const Header: PScriptHeader; const AFunction: PFunction;
      const AType: PType): TValue; virtual;
    function MilliSecondMethod(const Header: PScriptHeader; const AFunction: PFunction;
      const AType: PType): TValue; virtual;
    function DateTimeMethod(const Header: PScriptHeader; const AFunction: PFunction;
      const AType: PType): TValue; virtual;
    function DateMethod(const Header: PScriptHeader; const AFunction: PFunction;
      const AType: PType): TValue; virtual;
    function TimeMethod(const Header: PScriptHeader; const AFunction: PFunction;
      const AType: PType): TValue; virtual;
    function GetYearMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const PA: TParameterArray): TValue; virtual;
    function GetMonthMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const PA: TParameterArray): TValue; virtual;
    function GetDayMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const PA: TParameterArray): TValue; virtual;
    function GetDayOfWeekMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const PA: TParameterArray): TValue; virtual;
    function GetHourMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const PA: TParameterArray): TValue; virtual;
    function GetMinuteMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const PA: TParameterArray): TValue; virtual;
    function GetSecondMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const PA: TParameterArray): TValue; virtual;
    function GetMilliSecondMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const PA: TParameterArray): TValue; virtual;
    function EncodeDateTimeMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const PA: TParameterArray): TValue; virtual;
    function EncodeDateMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const PA: TParameterArray): TValue; virtual;
    function EncodeTimeMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const PA: TParameterArray): TValue; virtual;
    function StrToDateTimeMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const PA: TParameterArray): TValue; virtual;
    function StrToDateMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const PA: TParameterArray): TValue; virtual;
    function StrToTimeMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const PA: TParameterArray): TValue; virtual;
    function DateOfMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const Value: TValue): TValue; virtual;
    function TimeOfMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const Value: TValue): TValue; virtual;
    function YearOfMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const Value: TValue): TValue; virtual;
    function MonthOfMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const Value: TValue): TValue; virtual;
    function WeekOfMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const Value: TValue): TValue; virtual;
    function DayOfMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const Value: TValue): TValue; virtual;
    function HourOfMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const Value: TValue): TValue; virtual;
    function MinuteOfMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const Value: TValue): TValue; virtual;
    function SecondOfMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const Value: TValue): TValue; virtual;
    function MilliSecondOfMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const Value: TValue): TValue; virtual;
    function YearsBetweenMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const PA: TParameterArray): TValue; virtual;
    function MonthsBetweenMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const PA: TParameterArray): TValue; virtual;
    function WeeksBetweenMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const PA: TParameterArray): TValue; virtual;
    function DaysBetweenMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const PA: TParameterArray): TValue; virtual;
    function HoursBetweenMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const PA: TParameterArray): TValue; virtual;
    function MinutesBetweenMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const PA: TParameterArray): TValue; virtual;
    function SecondsBetweenMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const PA: TParameterArray): TValue; virtual;
    function MilliSecondsBetweenMethod(const Header: PScriptHeader; const AFunction: PFunction;
      const AType: PType; const PA: TParameterArray): TValue; virtual;
    function MonthOfTheYearMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const Value: TValue): TValue; virtual;
    function WeekOfTheYearMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const Value: TValue): TValue; virtual;
    function DayOfTheYearMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const Value: TValue): TValue; virtual;
    function HourOfTheYearMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const Value: TValue): TValue; virtual;
    function MinuteOfTheYearMethod(const Header: PScriptHeader; const AFunction: PFunction;
      const AType: PType; const Value: TValue): TValue; virtual;
    function SecondOfTheYearMethod(const Header: PScriptHeader; const AFunction: PFunction;
      const AType: PType; const Value: TValue): TValue; virtual;
    function MilliSecondOfTheYearMethod(const Header: PScriptHeader; const AFunction: PFunction;
      const AType: PType; const Value: TValue): TValue; virtual;
    function WeekOfTheMonthMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const Value: TValue): TValue; virtual;
    function DayOfTheMonthMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const Value: TValue): TValue; virtual;
    function HourOfTheMonthMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const Value: TValue): TValue; virtual;
    function MinuteOfTheMonthMethod(const Header: PScriptHeader; const AFunction: PFunction;
      const AType: PType; const Value: TValue): TValue; virtual;
    function SecondOfTheMonthMethod(const Header: PScriptHeader; const AFunction: PFunction;
      const AType: PType; const Value: TValue): TValue; virtual;
    function MilliSecondOfTheMonthMethod(const Header: PScriptHeader; const AFunction: PFunction;
      const AType: PType; const Value: TValue): TValue; virtual;
    function DayOfTheWeekMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const Value: TValue): TValue; virtual;
    function HourOfTheWeekMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const Value: TValue): TValue; virtual;
    function MinuteOfTheWeekMethod(const Header: PScriptHeader; const AFunction: PFunction;
      const AType: PType; const Value: TValue): TValue; virtual;
    function SecondOfTheWeekMethod(const Header: PScriptHeader; const AFunction: PFunction;
      const AType: PType; const Value: TValue): TValue; virtual;
    function MilliSecondOfTheWeekMethod(const Header: PScriptHeader; const AFunction: PFunction;
      const AType: PType; const Value: TValue): TValue; virtual;
    function HourOfTheDayMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const Value: TValue): TValue; virtual;
    function MinuteOfTheDayMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const Value: TValue): TValue; virtual;
    function SecondOfTheDayMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const Value: TValue): TValue; virtual;
    function MilliSecondOfTheDayMethod(const Header: PScriptHeader; const AFunction: PFunction;
      const AType: PType; const Value: TValue): TValue; virtual;
    function MinuteOfTheHourMethod(const Header: PScriptHeader; const AFunction: PFunction;
      const AType: PType; const Value: TValue): TValue; virtual;
    function SecondOfTheHourMethod(const Header: PScriptHeader; const AFunction: PFunction;
      const AType: PType; const Value: TValue): TValue; virtual;
    function MilliSecondOfTheHourMethod(const Header: PScriptHeader; const AFunction: PFunction;
      const AType: PType; const Value: TValue): TValue; virtual;
    function SecondOfTheMinuteMethod(const Header: PScriptHeader; const AFunction: PFunction;
      const AType: PType; const Value: TValue): TValue; virtual;
    function MilliSecondOfTheMinuteMethod(const Header: PScriptHeader; const AFunction: PFunction;
      const AType: PType; const Value: TValue): TValue; virtual;
    function MilliSecondOfTheSecondMethod(const Header: PScriptHeader; const AFunction: PFunction;
      const AType: PType; const Value: TValue): TValue; virtual;
    function CompareDateTimeMethod(const Header: PScriptHeader; const AFunction: PFunction;
      const AType: PType; const PA: TParameterArray): TValue; virtual;
    function SameDateTimeMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const PA: TParameterArray): TValue; virtual;
    function CompareDateMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const PA: TParameterArray): TValue; virtual;
    function SameDateMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const PA: TParameterArray): TValue; virtual;
    function CompareTimeMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const PA: TParameterArray): TValue; virtual;
    function SameTimeMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const PA: TParameterArray): TValue; virtual;
    function GetTickCount(const Header: PScriptHeader; const AFunction: PFunction;
      const AType: PType): TValue; virtual;
    function HypotMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const PA: TParameterArray): TValue; virtual;
    function RadToDegMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const Value: TValue): TValue; virtual;
    function RadToGradMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const Value: TValue): TValue; virtual;
    function RadToCycleMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const Value: TValue): TValue; virtual;
    function DegToRadMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const Value: TValue): TValue; virtual;
    function DegToGradMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const Value: TValue): TValue; virtual;
    function DegToCycleMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const Value: TValue): TValue; virtual;
    function GradToRadMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const Value: TValue): TValue; virtual;
    function GradToDegMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const Value: TValue): TValue; virtual;
    function GradToCycleMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const Value: TValue): TValue; virtual;
    function CycleToRadMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const Value: TValue): TValue; virtual;
    function CycleToDegMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const Value: TValue): TValue; virtual;
    function CycleToGradMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const Value: TValue): TValue; virtual;
    function LnXP1Method(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const Value: TValue): TValue; virtual;
    function Log10Method(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const Value: TValue): TValue; virtual;
    function Log2Method(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const Value: TValue): TValue; virtual;
    function IntPowerMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const PA: TParameterArray): TValue; virtual;
    function PowerMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const LValue, RValue: TValue): TValue; virtual;
    function RootMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const LValue, RValue: TValue): TValue; virtual;
    function LdexpMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const PA: TParameterArray): TValue; virtual;
    function CeilMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const Value: TValue): TValue; virtual;
    function FloorMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const Value: TValue): TValue; virtual;
    function PolyMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const PA: TParameterArray): TValue; virtual;
    function MeanMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const PA: TParameterArray): TValue; virtual;
    function SumMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const PA: TParameterArray): TValue; virtual;
    function SumIntMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const PA: TParameterArray): TValue; virtual;
    function SumOfSquaresMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const PA: TParameterArray): TValue; virtual;
    function MinValueMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const PA: TParameterArray): TValue; virtual;
    function MinIntValueMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const PA: TParameterArray): TValue; virtual;
    function MinMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const PA: TParameterArray): TValue; virtual;
    function MaxValueMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const PA: TParameterArray): TValue; virtual;
    function MaxIntValueMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const PA: TParameterArray): TValue; virtual;
    function MaxMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const PA: TParameterArray): TValue; virtual;
    function StdDevMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const PA: TParameterArray): TValue; virtual;
    function PopnStdDevMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const PA: TParameterArray): TValue; virtual;
    function VarianceMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const PA: TParameterArray): TValue; virtual;
    function PopnVarianceMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const PA: TParameterArray): TValue; virtual;
    function TotalVarianceMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const PA: TParameterArray): TValue; virtual;
    function NormMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const PA: TParameterArray): TValue; virtual;
    function RandGMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const PA: TParameterArray): TValue; virtual;
    function RandomRangeMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const PA: TParameterArray): TValue; virtual;
    function RandomFromMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const PA: TParameterArray): TValue; virtual;
  end;

  TValueRelationship = (vrBelow, vrEqual, vrAbove);
  TDoubleDynArray = array of Double;

const
  TypeError1 = '%s type found, but %s type expected for %s function parameter with index %d';
  TypeError2 = '%s type is not applicable for %s function parameter with index %d';

var
  MethodSync: TRTLCriticalSection;

procedure Check(const AFunction: PFunction; const PA: TParameterArray; const ParamCount: Integer;
  const Relationship: TValueRelationship = vrEqual); overload;
procedure Check(const AFunction: PFunction; const PA: TParameterArray;
  const ParamMinCount, ParamMaxCount: Integer); overload;
procedure Check(const Parser: TObject; const AFunction: PFunction; const Index, THandle: Integer;
  const TextFlag: Boolean); overload;
procedure Check(const Parser: TObject; const AFunction: PFunction; const PA: TParameterArray;
  const TextFlag: Boolean); overload;
procedure Check(const ValueType: TValueType); overload;

function CleanDateTime(const Source: string): string;

function FArray(const PA: TParameterArray; const FromIndex, TillIndex: Integer): TDoubleDynArray;
function IArray(const PA: TParameterArray; const FromIndex, TillIndex: Integer): TIntegerDynArray;

function Factorial(const Value: Smallint): Int64;

implementation

uses
  {$IFDEF FPC}
  Math, DateUtils, MemoryUtils, NumberConsts, NumberUtils, ParseCommon, ParseConsts,
  ParseErrors, ParseManager, Parser, ParseUtils, TextTypes, ThreadUtils, ValueConsts,
  ScriptFormat, ValueErrors, ValueUtils;
  {$ELSE}
  {$IFDEF DELPHI_XE7}
  System.Math, System.DateUtils, MemoryUtils, NumberConsts, NumberUtils, ParseCommon,
  ParseConsts, ParseErrors, ParseManager, Parser, ParseUtils, TextTypes, ThreadUtils,
  ValueConsts, ScriptFormat, ValueErrors, ValueUtils;
  {$ELSE}
  Math, DateUtils, MemoryUtils, NumberConsts, NumberUtils, ParseCommon, ParseConsts,
  ParseErrors, ParseManager, Parser, ParseUtils, TextTypes, ThreadUtils, ValueConsts,
  ScriptFormat, ValueErrors, ValueUtils;
  {$ENDIF}
  {$ENDIF}

procedure Check(const AFunction: PFunction; const PA: TParameterArray; const ParamCount: Integer;
  const Relationship: TValueRelationship);
begin
  case Relationship of
    vrBelow:
      if Length(PA) < ParamCount then
        raise ParseErrors.Error(BParamExpectError, [AFunction.Name]);
    vrEqual:
      begin
        if Length(PA) < ParamCount then
          raise ParseErrors.Error(BParamExpectError, [AFunction.Name]);
        if Length(PA) > ParamCount then
          raise ParseErrors.Error(BParamExcessError, [AFunction.Name]);
      end;
    vrAbove:
      if Length(PA) > ParamCount then
        raise ParseErrors.Error(BParamExcessError, [AFunction.Name]);
  end;
end;

procedure Check(const AFunction: PFunction; const PA: TParameterArray;
  const ParamMinCount, ParamMaxCount: Integer);
begin
  Check(AFunction, PA, ParamMinCount, vrBelow);
  Check(AFunction, PA, ParamMaxCount, vrAbove);
end;

procedure Check(const Parser: TObject; const AFunction: PFunction; const Index, THandle: Integer;
  const TextFlag: Boolean);
var
  P: TParser absolute Parser;
  AType, BType: PType;
begin
  if P.GetType(THandle, AType) and P.GetType(P.StringHandle, BType) then
  begin
    if TextFlag and (THandle <> P.StringHandle) then
      raise ParseErrors.Error(TypeError1, [AType.Name, BType.Name, AFunction.Name, Index + 1]);
    if not TextFlag and (THandle = P.StringHandle) then
      raise ParseErrors.Error(TypeError2, [AType.Name, AFunction.Name, Index + 1]);
  end;
end;

procedure Check(const Parser: TObject; const AFunction: PFunction; const PA: TParameterArray;
  const TextFlag: Boolean);
var
  I: Integer;
begin
  for I := Low(PA) to High(PA) do
    Check(Parser, AFunction, I, PA[I].THandle, TextFlag);
end;

procedure Check(const ValueType: TValueType);
begin
  if not (ValueType in ValidTypeSet) then raise ParseErrors.Error(TypeError);
end;

function CleanDateTime(const Source: string): string;

  procedure Put(var S: string; const C: Char; var Index: Integer);
  begin
    S[Index] := C;
    Inc(Index);
  end;

const
  DateDelimiter = '.';
  TimeDelimiter = ':';
var
  I, J, K: Integer;
  C: Char;
begin
  K := Length(Source);
  SetLength(Result, K);
  J := 1;
  for I := 1 to K do
  begin
    C := Source[I];
    case C of
      '0'..'9': Put(Result, C, J);
      DateDelimiter: if (I > 1) and (I < K) then Put(Result, {$IFDEF DELPHI_XE7}FormatSettings.{$ENDIF}DateSeparator, J);
      TimeDelimiter: if (I > 1) and (I < K) then Put(Result, {$IFDEF DELPHI_XE7}FormatSettings.{$ENDIF}TimeSeparator, J);
      ' ': if (J > 1) and (Result[J - 1] <> ' ') then Put(Result, ' ', J);
    end;
  end;
  SetLength(Result, J - 1);
end;

function FArray(const PA: TParameterArray; const FromIndex, TillIndex: Integer): TDoubleDynArray;
var
  I: Integer;
begin
  if TillIndex < FromIndex then
    SetLength(Result, 0)
  else
    SetLength(Result, TillIndex - FromIndex + 1);
  for I := FromIndex to TillIndex do
    Result[I - FromIndex] := GetExtended(PA[I].Value);
end;

function IArray(const PA: TParameterArray; const FromIndex, TillIndex: Integer): TIntegerDynArray;
var
  I: Integer;
begin
  SetLength(Result, Length(PA));
  for I := FromIndex to TillIndex do Result[I] := GetInteger(PA[I].Value);
end;

function Factorial(const Value: Smallint): Int64;
var
  I: Integer;
begin
  Result := 1;
  for I := 1 to Value do Result := Result * I;
end;

{ TVariableContainer }

procedure TVariableContainer.Clear;
var
  I: Integer;
  Value: PValue;
begin
  for I := 0 to FList.List.Count - 1 do
  begin
    Value := PValue(FList.List.Objects[I]);
    if Assigned(Value) then Dispose(Value);
  end;
end;

constructor TVariableContainer.Create;
begin
  FList := TFlexibleList.Create(nil);
end;

function TVariableContainer.Delete(const Name: string): Boolean;
var
  I: Integer;
  Value: PValue;
begin
  Result := Find(Name, @I);
  if Result then
  begin
    Value := PValue(FList.List.Objects[I]);
    if Assigned(Value) then Dispose(Value);
    FList.List.Delete(I);
  end;
end;

destructor TVariableContainer.Destroy;
begin
  Clear;
  FList.Free;
  inherited;
end;

function TVariableContainer.Find(const Name: string;
  Index: {$IFDEF FPC}System.{$ENDIF}PInteger): Boolean;
var
  I: Integer;
begin
  if not Assigned(Index) then Index := @I;
  Index^ := ParseCommon.IndexOf(FList.List, Name, False);
  Result := Index^ >= 0;
end;

procedure TVariableContainer.SetVariable(const Name: string; const Value: PValue);
var
  I: Integer;
begin
  if Find(Name, @I) then FList.List.Objects[I] := TObject(Value)
  else
    FList.List.AddObject(Name, TObject(Value));
end;

{ TCustomMethod }

constructor TCustomMethod.Create(const AParser: TObject);
begin
  FParser := AParser;
end;

{ TMethod }

function TMethod.AboveMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const LValue, RValue: TValue): TValue;
var
  P: TParser;
begin
  Check(LValue.ValueType);
  Check(RValue.ValueType);
  P := TParser(FParser);
  Result := EmptyValue;
  case LValue.ValueType of
    vtByte:
      case RValue.ValueType of
        vtByte:
          if LValue.Unsigned8 > RValue.Unsigned8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtShortint:
          if Int64(LValue.Unsigned8) > RValue.Signed8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtWord:
          if LValue.Unsigned8 > RValue.Unsigned16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSmallint:
          if LValue.Unsigned8 > RValue.Signed16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtLongWord:
          if LValue.Unsigned8 > RValue.Unsigned32 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInteger:
          if LValue.Unsigned8 > RValue.Signed32 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeInt:
          if LValue.Unsigned8 > RValue.NativeInt then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeUInt:
          if LValue.Unsigned8 > RValue.NativeUInt then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInt64:
          if LValue.Unsigned8 > RValue.Signed64 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSingle:
          if Above(LValue.Unsigned8, RValue.Float32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtDouble:
          if Above(LValue.Unsigned8, RValue.Float64) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtExtended:
          if Above(LValue.Unsigned8, RValue.Float80) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
      end;
    vtShortint:
      case RValue.ValueType of
        vtByte:
          if LValue.Signed8 > Int64(RValue.Unsigned8) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtShortint:
          if LValue.Signed8 > RValue.Signed8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtWord:
          if LValue.Signed8 > Int64(RValue.Unsigned16) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSmallint:
          if LValue.Signed8 > RValue.Signed16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtLongWord:
          if LValue.Signed8 > Int64(RValue.Unsigned32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInteger:
          if LValue.Signed8 > RValue.Signed32 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeInt:
          if LValue.Signed8 > RValue.NativeInt then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeUInt:
          if LValue.Signed8 > Int64(RValue.NativeUInt) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInt64:
          if LValue.Signed8 > RValue.Signed64 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSingle:
          if Above(LValue.Signed8, RValue.Float32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtDouble:
          if Above(LValue.Signed8, RValue.Float64) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtExtended:
          if Above(LValue.Signed8, RValue.Float80) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
      end;
    vtWord:
      case RValue.ValueType of
        vtByte:
          if LValue.Unsigned16 > RValue.Unsigned8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtShortint:
          if Int64(LValue.Unsigned16) > RValue.Signed8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtWord:
          if LValue.Unsigned16 > RValue.Unsigned16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSmallint:
          if Int64(LValue.Unsigned16) > RValue.Signed16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtLongWord:
          if LValue.Unsigned16 > RValue.Unsigned32 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInteger:
          if LValue.Unsigned16 > RValue.Signed32 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeInt:
          if LValue.Unsigned16 > RValue.NativeInt then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeUInt:
          if LValue.Unsigned16 > RValue.NativeUInt then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInt64:
          if LValue.Unsigned16 > RValue.Signed64 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSingle:
          if Above(LValue.Unsigned16, RValue.Float32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtDouble:
          if Above(LValue.Unsigned16, RValue.Float64) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtExtended:
          if Above(LValue.Unsigned16, RValue.Float80) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
      end;
    vtSmallint:
      case RValue.ValueType of
        vtByte:
          if LValue.Signed16 > RValue.Unsigned8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtShortint:
          if LValue.Signed16 > RValue.Signed8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtWord:
          if LValue.Signed16 > Int64(RValue.Unsigned16) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSmallint:
          if LValue.Signed16 > RValue.Signed16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtLongWord:
          if LValue.Signed16 > Int64(RValue.Unsigned32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInteger:
          if LValue.Signed16 > RValue.Signed32 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeInt:
          if LValue.Signed16 > RValue.NativeInt then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeUInt:
          if LValue.Signed16 > Int64(RValue.NativeUInt) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInt64:
          if LValue.Signed16 > RValue.Signed64 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSingle:
          if Above(LValue.Signed16, RValue.Float32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtDouble:
          if Above(LValue.Signed16, RValue.Float64) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtExtended:
          if Above(LValue.Signed16, RValue.Float80) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
      end;
    vtLongWord:
      case RValue.ValueType of
        vtByte:
          if LValue.Unsigned32 > RValue.Unsigned8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtShortint:
          if Int64(LValue.Unsigned32) > RValue.Signed8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtWord:
          if LValue.Unsigned32 > RValue.Unsigned16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSmallint:
          if Int64(LValue.Unsigned32) > RValue.Signed16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtLongWord:
          if LValue.Unsigned32 > RValue.Unsigned32 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInteger:
          if Int64(LValue.Unsigned32) > RValue.Signed32 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeInt:
          if Int64(LValue.Unsigned32) > RValue.NativeInt then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeUInt:
          if LValue.Unsigned32 > RValue.NativeUInt then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInt64:
          if LValue.Unsigned32 > RValue.Signed64 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSingle:
          if Above(LValue.Unsigned32, RValue.Float32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtDouble:
          if Above(LValue.Unsigned32, RValue.Float64) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtExtended:
          if Above(LValue.Unsigned32, RValue.Float80) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
      end;
    vtInteger:
      case RValue.ValueType of
        vtByte:
          if LValue.Signed32 > RValue.Unsigned8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtShortint:
          if LValue.Signed32 > RValue.Signed8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtWord:
          if LValue.Signed32 > RValue.Unsigned16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSmallint:
          if LValue.Signed32 > RValue.Signed16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtLongWord:
          if LValue.Signed32 > Int64(RValue.Unsigned32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInteger:
          if LValue.Signed32 > RValue.Signed32 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeInt:
          if LValue.Signed32 > RValue.NativeInt then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeUInt:
          if LValue.Signed32 > Int64(RValue.NativeUInt) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInt64:
          if LValue.Signed32 > RValue.Signed64 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSingle:
          if Above(LValue.Signed32, RValue.Float32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtDouble:
          if Above(LValue.Signed32, RValue.Float64) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtExtended:
          if Above(LValue.Signed32, RValue.Float80) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
      end;
    vtNativeInt:
      case RValue.ValueType of
        vtByte:
          if LValue.NativeInt > RValue.Unsigned8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtShortint:
          if LValue.NativeInt > RValue.Signed8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtWord:
          if LValue.NativeInt > RValue.Unsigned16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSmallint:
          if LValue.NativeInt > RValue.Signed16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtLongWord:
          if LValue.NativeInt > Int64(RValue.Unsigned32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInteger:
          if LValue.NativeInt > RValue.Signed32 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeInt:
          if LValue.NativeInt > RValue.NativeInt then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeUInt:
          if LValue.NativeInt > Int64(RValue.NativeUInt) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInt64:
          if LValue.NativeInt > RValue.Signed64 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSingle:
          if Above(LValue.NativeInt, RValue.Float32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtDouble:
          if Above(LValue.NativeInt, RValue.Float64) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtExtended:
          if Above(LValue.NativeInt, RValue.Float80) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
      end;
    vtNativeUInt:
      case RValue.ValueType of
        vtByte:
          if LValue.NativeUInt > RValue.Unsigned8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtShortint:
          if Int64(LValue.NativeUInt) > RValue.Signed8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtWord:
          if LValue.NativeUInt > RValue.Unsigned16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSmallint:
          if Int64(LValue.NativeUInt) > RValue.Signed16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtLongWord:
          if LValue.NativeUInt > RValue.Unsigned32 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInteger:
          if Int64(LValue.NativeUInt) > RValue.Signed32 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeInt:
          if Int64(LValue.NativeUInt) > RValue.NativeInt then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeUInt:
          if LValue.NativeUInt > RValue.NativeUInt then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInt64:
          if LValue.NativeUInt > RValue.Signed64 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSingle:
          if Above(LValue.NativeUInt, RValue.Float32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtDouble:
          if Above(LValue.NativeUInt, RValue.Float64) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtExtended:
          if Above(LValue.NativeUInt, RValue.Float80) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
      end;
    vtInt64:
      case RValue.ValueType of
        vtByte:
          if LValue.Signed64 > RValue.Unsigned8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtShortint:
          if LValue.Signed64 > RValue.Signed8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtWord:
          if LValue.Signed64 > RValue.Unsigned16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSmallint:
          if LValue.Signed64 > RValue.Signed16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtLongWord:
          if LValue.Signed64 > RValue.Unsigned32 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInteger:
          if LValue.Signed64 > RValue.Signed32 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeInt:
          if LValue.Signed64 > RValue.NativeInt then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeUInt:
          if LValue.Signed64 > RValue.NativeUInt then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInt64:
          if LValue.Signed64 > RValue.Signed64 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSingle:
          if Above(LValue.Signed64, RValue.Float32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtDouble:
          if Above(LValue.Signed64, RValue.Float64) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtExtended:
          if Above(LValue.Signed64, RValue.Float80) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
      end;
    vtSingle:
      case RValue.ValueType of
        vtByte:
          if Above(LValue.Float32, RValue.Unsigned8) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtShortint:
          if Above(LValue.Float32, RValue.Signed8) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtWord:
          if Above(LValue.Float32, RValue.Unsigned16) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSmallint:
          if Above(LValue.Float32, RValue.Signed16) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtLongWord:
          if Above(LValue.Float32, RValue.Unsigned32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInteger:
          if Above(LValue.Float32, RValue.Signed32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeInt:
          if Above(LValue.Float32, RValue.NativeInt) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeUInt:
          if Above(LValue.Float32, RValue.NativeUInt) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInt64:
          if Above(LValue.Float32, RValue.Signed64) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSingle:
          if Above(LValue.Float32, RValue.Float32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtDouble:
          if Above(LValue.Float32, RValue.Float64) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtExtended:
          if Above(LValue.Float32, RValue.Float80) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
      end;
    vtDouble:
      case RValue.ValueType of
        vtByte:
          if Above(LValue.Float64, RValue.Unsigned8) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtShortint:
          if Above(LValue.Float64, RValue.Signed8) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtWord:
          if Above(LValue.Float64, RValue.Unsigned16) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSmallint:
          if Above(LValue.Float64, RValue.Signed16) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtLongWord:
          if Above(LValue.Float64, RValue.Unsigned32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInteger:
          if Above(LValue.Float64, RValue.Signed32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeInt:
          if Above(LValue.Float64, RValue.NativeInt) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeUInt:
          if Above(LValue.Float64, RValue.NativeUInt) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInt64:
          if Above(LValue.Float64, RValue.Signed64) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSingle:
          if Above(LValue.Float64, RValue.Float32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtDouble:
          if Above(LValue.Float64, RValue.Float64) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtExtended:
          if Above(LValue.Float64, RValue.Float80) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
      end;
    vtExtended:
      case RValue.ValueType of
        vtByte:
          if Above(LValue.Float80, RValue.Unsigned8) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtShortint:
          if Above(LValue.Float80, RValue.Signed8) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtWord:
          if Above(LValue.Float80, RValue.Unsigned16) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSmallint:
          if Above(LValue.Float80, RValue.Signed16) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtLongWord:
          if Above(LValue.Float80, RValue.Unsigned32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInteger:
          if Above(LValue.Float80, RValue.Signed32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeInt:
          if Above(LValue.Float80, RValue.NativeInt) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeUInt:
          if Above(LValue.Float80, RValue.NativeUInt) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInt64:
          if Above(LValue.Float80, RValue.Signed64) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSingle:
          if Above(LValue.Float80, RValue.Float32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtDouble:
          if Above(LValue.Float80, RValue.Float64) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtExtended:
          if Above(LValue.Float80, RValue.Float80) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
      end;
  end;
  Result.ValueType := vtInteger;
end;

function TMethod.AboveOrEqualMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const LValue, RValue: TValue): TValue;
var
  P: TParser;
begin
  Check(LValue.ValueType);
  Check(RValue.ValueType);
  P := TParser(FParser);
  Result := EmptyValue;
  case LValue.ValueType of
    vtByte:
      case RValue.ValueType of
        vtByte:
          if LValue.Unsigned8 >= RValue.Unsigned8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtShortint:
          if Int64(LValue.Unsigned8) >= RValue.Signed8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtWord:
          if LValue.Unsigned8 >= RValue.Unsigned16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSmallint:
          if LValue.Unsigned8 >= RValue.Signed16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtLongWord:
          if LValue.Unsigned8 >= RValue.Unsigned32 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInteger:
          if LValue.Unsigned8 >= RValue.Signed32 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeInt:
          if LValue.Unsigned8 >= RValue.NativeInt then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeUInt:
          if LValue.Unsigned8 >= RValue.NativeUInt then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInt64:
          if LValue.Unsigned8 >= RValue.Signed64 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSingle:
          if AboveOrEqual(LValue.Unsigned8, RValue.Float32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtDouble:
          if AboveOrEqual(LValue.Unsigned8, RValue.Float64) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtExtended:
          if AboveOrEqual(LValue.Unsigned8, RValue.Float80) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
      end;
    vtShortint:
      case RValue.ValueType of
        vtByte:
          if LValue.Signed8 >= Int64(RValue.Unsigned8) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtShortint:
          if LValue.Signed8 >= RValue.Signed8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtWord:
          if LValue.Signed8 >= Int64(RValue.Unsigned16) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSmallint:
          if LValue.Signed8 >= RValue.Signed16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtLongWord:
          if LValue.Signed8 >= Int64(RValue.Unsigned32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInteger:
          if LValue.Signed8 >= RValue.Signed32 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeInt:
          if LValue.Signed8 >= RValue.NativeInt then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeUInt:
          if LValue.Signed8 >= Int64(RValue.NativeUInt) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInt64:
          if LValue.Signed8 >= RValue.Signed64 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSingle:
          if AboveOrEqual(LValue.Signed8, RValue.Float32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtDouble:
          if AboveOrEqual(LValue.Signed8, RValue.Float64) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtExtended:
          if AboveOrEqual(LValue.Signed8, RValue.Float80) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
      end;
    vtWord:
      case RValue.ValueType of
        vtByte:
          if LValue.Unsigned16 >= RValue.Unsigned8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtShortint:
          if Int64(LValue.Unsigned16) >= RValue.Signed8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtWord:
          if LValue.Unsigned16 >= RValue.Unsigned16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSmallint:
          if Int64(LValue.Unsigned16) >= RValue.Signed16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtLongWord:
          if LValue.Unsigned16 >= RValue.Unsigned32 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInteger:
          if LValue.Unsigned16 >= RValue.Signed32 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeInt:
          if LValue.Unsigned16 >= RValue.NativeInt then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeUInt:
          if LValue.Unsigned16 >= RValue.NativeUInt then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInt64:
          if LValue.Unsigned16 >= RValue.Signed64 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSingle:
          if AboveOrEqual(LValue.Unsigned16, RValue.Float32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtDouble:
          if AboveOrEqual(LValue.Unsigned16, RValue.Float64) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtExtended:
          if AboveOrEqual(LValue.Unsigned16, RValue.Float80) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
      end;
    vtSmallint:
      case RValue.ValueType of
        vtByte:
          if LValue.Signed16 >= RValue.Unsigned8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtShortint:
          if LValue.Signed16 >= RValue.Signed8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtWord:
          if LValue.Signed16 >= Int64(RValue.Unsigned16) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSmallint:
          if LValue.Signed16 >= RValue.Signed16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtLongWord:
          if LValue.Signed16 >= Int64(RValue.Unsigned32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInteger:
          if LValue.Signed16 >= RValue.Signed32 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeInt:
          if LValue.Signed16 >= RValue.NativeInt then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeUInt:
          if LValue.Signed16 >= Int64(RValue.NativeUInt) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInt64:
          if LValue.Signed16 >= RValue.Signed64 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSingle:
          if AboveOrEqual(LValue.Signed16, RValue.Float32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtDouble:
          if AboveOrEqual(LValue.Signed16, RValue.Float64) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtExtended:
          if AboveOrEqual(LValue.Signed16, RValue.Float80) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
      end;
    vtLongWord:
      case RValue.ValueType of
        vtByte:
          if LValue.Unsigned32 >= RValue.Unsigned8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtShortint:
          if Int64(LValue.Unsigned32) >= RValue.Signed8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtWord:
          if LValue.Unsigned32 >= RValue.Unsigned16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSmallint:
          if Int64(LValue.Unsigned32) >= RValue.Signed16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtLongWord:
          if LValue.Unsigned32 >= RValue.Unsigned32 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInteger:
          if Int64(LValue.Unsigned32) >= RValue.Signed32 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeInt:
          if Int64(LValue.Unsigned32) >= RValue.NativeInt then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeUInt:
          if LValue.Unsigned32 >= RValue.NativeUInt then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInt64:
          if LValue.Unsigned32 >= RValue.Signed64 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSingle:
          if AboveOrEqual(LValue.Unsigned32, RValue.Float32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtDouble:
          if AboveOrEqual(LValue.Unsigned32, RValue.Float64) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtExtended:
          if AboveOrEqual(LValue.Unsigned32, RValue.Float80) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
      end;
    vtInteger:
      case RValue.ValueType of
        vtByte:
          if LValue.Signed32 >= RValue.Unsigned8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtShortint:
          if LValue.Signed32 >= RValue.Signed8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtWord:
          if LValue.Signed32 >= RValue.Unsigned16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSmallint:
          if LValue.Signed32 >= RValue.Signed16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtLongWord:
          if LValue.Signed32 >= Int64(RValue.Unsigned32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInteger:
          if LValue.Signed32 >= RValue.Signed32 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeInt:
          if LValue.Signed32 >= RValue.NativeInt then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeUInt:
          if LValue.Signed32 >= Int64(RValue.NativeUInt) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInt64:
          if LValue.Signed32 >= RValue.Signed64 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSingle:
          if AboveOrEqual(LValue.Signed32, RValue.Float32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtDouble:
          if AboveOrEqual(LValue.Signed32, RValue.Float64) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtExtended:
          if AboveOrEqual(LValue.Signed32, RValue.Float80) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
      end;
    vtNativeInt:
      case RValue.ValueType of
        vtByte:
          if LValue.NativeInt >= RValue.Unsigned8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtShortint:
          if LValue.NativeInt >= RValue.Signed8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtWord:
          if LValue.NativeInt >= RValue.Unsigned16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSmallint:
          if LValue.NativeInt >= RValue.Signed16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtLongWord:
          if LValue.NativeInt >= Int64(RValue.Unsigned32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInteger:
          if LValue.NativeInt >= RValue.Signed32 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeInt:
          if LValue.NativeInt >= RValue.NativeInt then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeUInt:
          if LValue.NativeInt >= Int64(RValue.NativeUInt) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInt64:
          if LValue.NativeInt >= RValue.Signed64 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSingle:
          if AboveOrEqual(LValue.NativeInt, RValue.Float32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtDouble:
          if AboveOrEqual(LValue.NativeInt, RValue.Float64) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtExtended:
          if AboveOrEqual(LValue.NativeInt, RValue.Float80) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
      end;
    vtNativeUInt:
      case RValue.ValueType of
        vtByte:
          if LValue.NativeUInt >= RValue.Unsigned8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtShortint:
          if Int64(LValue.NativeUInt) >= RValue.Signed8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtWord:
          if LValue.NativeUInt >= RValue.Unsigned16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSmallint:
          if Int64(LValue.NativeUInt) >= RValue.Signed16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtLongWord:
          if LValue.NativeUInt >= RValue.Unsigned32 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInteger:
          if Int64(LValue.NativeUInt) >= RValue.Signed32 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeInt:
          if Int64(LValue.NativeUInt) >= RValue.NativeInt then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeUInt:
          if LValue.NativeUInt >= RValue.NativeUInt then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInt64:
          if LValue.NativeUInt >= RValue.Signed64 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSingle:
          if AboveOrEqual(LValue.NativeUInt, RValue.Float32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtDouble:
          if AboveOrEqual(LValue.NativeUInt, RValue.Float64) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtExtended:
          if AboveOrEqual(LValue.NativeUInt, RValue.Float80) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
      end;
    vtInt64:
      case RValue.ValueType of
        vtByte:
          if LValue.Signed64 >= RValue.Unsigned8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtShortint:
          if LValue.Signed64 >= RValue.Signed8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtWord:
          if LValue.Signed64 >= RValue.Unsigned16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSmallint:
          if LValue.Signed64 >= RValue.Signed16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtLongWord:
          if LValue.Signed64 >= RValue.Unsigned32 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInteger:
          if LValue.Signed64 >= RValue.Signed32 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeInt:
          if LValue.Signed64 >= RValue.NativeInt then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeUInt:
          if LValue.Signed64 >= RValue.NativeUInt then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInt64:
          if LValue.Signed64 >= RValue.Signed64 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSingle:
          if AboveOrEqual(LValue.Signed64, RValue.Float32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtDouble:
          if AboveOrEqual(LValue.Signed64, RValue.Float64) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtExtended:
          if AboveOrEqual(LValue.Signed64, RValue.Float80) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
      end;
    vtSingle:
      case RValue.ValueType of
        vtByte:
          if AboveOrEqual(LValue.Float32, RValue.Unsigned8) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtShortint:
          if AboveOrEqual(LValue.Float32, RValue.Signed8) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtWord:
          if AboveOrEqual(LValue.Float32, RValue.Unsigned16) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSmallint:
          if AboveOrEqual(LValue.Float32, RValue.Signed16) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtLongWord:
          if AboveOrEqual(LValue.Float32, RValue.Unsigned32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInteger:
          if AboveOrEqual(LValue.Float32, RValue.Signed32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeInt:
          if AboveOrEqual(LValue.Float32, RValue.NativeInt) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeUInt:
          if AboveOrEqual(LValue.Float32, RValue.NativeUInt) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInt64:
          if AboveOrEqual(LValue.Float32, RValue.Signed64) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSingle:
          if AboveOrEqual(LValue.Float32, RValue.Float32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtDouble:
          if AboveOrEqual(LValue.Float32, RValue.Float64) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtExtended:
          if AboveOrEqual(LValue.Float32, RValue.Float80) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
      end;
    vtDouble:
      case RValue.ValueType of
        vtByte:
          if AboveOrEqual(LValue.Float64, RValue.Unsigned8) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtShortint:
          if AboveOrEqual(LValue.Float64, RValue.Signed8) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtWord:
          if AboveOrEqual(LValue.Float64, RValue.Unsigned16) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSmallint:
          if AboveOrEqual(LValue.Float64, RValue.Signed16) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtLongWord:
          if AboveOrEqual(LValue.Float64, RValue.Unsigned32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInteger:
          if AboveOrEqual(LValue.Float64, RValue.Signed32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeInt:
          if AboveOrEqual(LValue.Float64, RValue.NativeInt) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeUInt:
          if AboveOrEqual(LValue.Float64, RValue.NativeUInt) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInt64:
          if AboveOrEqual(LValue.Float64, RValue.Signed64) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSingle:
          if AboveOrEqual(LValue.Float64, RValue.Float32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtDouble:
          if AboveOrEqual(LValue.Float64, RValue.Float64) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtExtended:
          if AboveOrEqual(LValue.Float64, RValue.Float80) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
      end;
    vtExtended:
      case RValue.ValueType of
        vtByte:
          if AboveOrEqual(LValue.Float80, RValue.Unsigned8) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtShortint:
          if AboveOrEqual(LValue.Float80, RValue.Signed8) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtWord:
          if AboveOrEqual(LValue.Float80, RValue.Unsigned16) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSmallint:
          if AboveOrEqual(LValue.Float80, RValue.Signed16) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtLongWord:
          if AboveOrEqual(LValue.Float80, RValue.Unsigned32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInteger:
          if AboveOrEqual(LValue.Float80, RValue.Signed32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeInt:
          if AboveOrEqual(LValue.Float80, RValue.NativeInt) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeUInt:
          if AboveOrEqual(LValue.Float80, RValue.NativeUInt) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInt64:
          if AboveOrEqual(LValue.Float80, RValue.Signed64) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSingle:
          if AboveOrEqual(LValue.Float80, RValue.Float32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtDouble:
          if AboveOrEqual(LValue.Float80, RValue.Float64) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtExtended:
          if AboveOrEqual(LValue.Float80, RValue.Float80) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
      end;
  end;
  Result.ValueType := vtInteger;
end;

function TMethod.AndMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const LValue, RValue: TValue): TValue;
begin
  Check(LValue.ValueType);
  Check(RValue.ValueType);
  Result := EmptyValue;
  case LValue.ValueType of
    vtByte:
      case RValue.ValueType of
        vtByte: AssignInteger(Result, LValue.Unsigned8 and RValue.Unsigned8);
        vtShortint: AssignInteger(Result, LValue.Unsigned8 and RValue.Signed8);
        vtWord: AssignInteger(Result, LValue.Unsigned8 and RValue.Unsigned16);
        vtSmallint: AssignInteger(Result, LValue.Unsigned8 and RValue.Signed16);
        vtLongWord: AssignInt64(Result, Int64(LValue.Unsigned8) and Int64(RValue.Unsigned32));
        vtInteger: AssignInt64(Result, Int64(LValue.Unsigned8) and Int64(RValue.Signed32));
        vtNativeInt: AssignInt64(Result, Int64(LValue.Unsigned8) and Int64(RValue.NativeInt));
        vtNativeUInt: AssignInt64(Result, Int64(LValue.Unsigned8) and Int64(RValue.NativeUInt));
        vtInt64: AssignInt64(Result, Int64(LValue.Unsigned8) and RValue.Signed64);
        vtSingle: AssignSingle(Result, LValue.Unsigned8 and Round(RValue.Float32));
        vtDouble: AssignDouble(Result, LValue.Unsigned8 and Round(RValue.Float64));
        vtExtended: AssignExtended(Result, LValue.Unsigned8 and Round(RValue.Float80));
      end;
    vtShortint:
      case RValue.ValueType of
        vtByte: AssignInteger(Result, LValue.Signed8 and RValue.Unsigned8);
        vtShortint: AssignInteger(Result, LValue.Signed8 and RValue.Signed8);
        vtWord: AssignInteger(Result, LValue.Signed8 and RValue.Unsigned16);
        vtSmallint: AssignInteger(Result, LValue.Signed8 and RValue.Signed16);
        vtLongWord: AssignInt64(Result, Int64(LValue.Signed8) and Int64(RValue.Unsigned32));
        vtInteger: AssignInt64(Result, Int64(LValue.Signed8) and Int64(RValue.Signed32));
        vtNativeInt: AssignInt64(Result, Int64(LValue.Signed8) and Int64(RValue.NativeInt));
        vtNativeUInt: AssignInt64(Result, Int64(LValue.Signed8) and Int64(RValue.NativeUInt));
        vtInt64: AssignInt64(Result, Int64(LValue.Signed8) and RValue.Signed64);
        vtSingle: AssignSingle(Result, LValue.Signed8 and Round(RValue.Float32));
        vtDouble: AssignDouble(Result, LValue.Signed8 and Round(RValue.Float64));
        vtExtended: AssignExtended(Result, LValue.Signed8 and Round(RValue.Float80));
      end;
    vtWord:
      case RValue.ValueType of
        vtByte: AssignInteger(Result, LValue.Unsigned16 and RValue.Unsigned8);
        vtShortint: AssignInteger(Result, LValue.Unsigned16 and RValue.Signed8);
        vtWord: AssignInteger(Result, LValue.Unsigned16 and RValue.Unsigned16);
        vtSmallint: AssignInteger(Result, LValue.Unsigned16 and RValue.Signed16);
        vtLongWord: AssignInt64(Result, Int64(LValue.Unsigned16) and Int64(RValue.Unsigned32));
        vtInteger: AssignInt64(Result, Int64(LValue.Unsigned16) and Int64(RValue.Signed32));
        vtNativeInt: AssignInt64(Result, Int64(LValue.Unsigned16) and Int64(RValue.NativeInt));
        vtNativeUInt: AssignInt64(Result, Int64(LValue.Unsigned16) and Int64(RValue.NativeUInt));
        vtInt64: AssignInt64(Result, Int64(LValue.Unsigned16) and RValue.Signed64);
        vtSingle: AssignSingle(Result, LValue.Unsigned16 and Round(RValue.Float32));
        vtDouble: AssignDouble(Result, LValue.Unsigned16 and Round(RValue.Float64));
        vtExtended: AssignExtended(Result, LValue.Unsigned16 and Round(RValue.Float80));
      end;
    vtSmallint:
      case RValue.ValueType of
        vtByte: AssignInteger(Result, LValue.Signed16 and RValue.Unsigned8);
        vtShortint: AssignInteger(Result, LValue.Signed16 and RValue.Signed8);
        vtWord: AssignInteger(Result, LValue.Signed16 and RValue.Unsigned16);
        vtSmallint: AssignInteger(Result, LValue.Signed16 and RValue.Signed16);
        vtLongWord: AssignInt64(Result, Int64(LValue.Signed16) and Int64(RValue.Unsigned32));
        vtInteger: AssignInt64(Result, Int64(LValue.Signed16) and Int64(RValue.Signed32));
        vtNativeInt: AssignInt64(Result, Int64(LValue.Signed16) and Int64(RValue.NativeInt));
        vtNativeUInt: AssignInt64(Result, Int64(LValue.Signed16) and Int64(RValue.NativeUInt));
        vtInt64: AssignInt64(Result, Int64(LValue.Signed16) and RValue.Signed64);
        vtSingle: AssignSingle(Result, LValue.Signed16 and Round(RValue.Float32));
        vtDouble: AssignDouble(Result, LValue.Signed16 and Round(RValue.Float64));
        vtExtended: AssignExtended(Result, LValue.Signed16 and Round(RValue.Float80));
      end;
    vtLongWord:
      case RValue.ValueType of
        vtByte: AssignInt64(Result, Int64(LValue.Unsigned32) and Int64(RValue.Unsigned8));
        vtShortint: AssignInt64(Result, Int64(LValue.Unsigned32) and Int64(RValue.Signed8));
        vtWord: AssignInt64(Result, Int64(LValue.Unsigned32) and Int64(RValue.Unsigned16));
        vtSmallint: AssignInt64(Result, Int64(LValue.Unsigned32) and Int64(RValue.Signed16));
        vtLongWord: AssignInt64(Result, Int64(LValue.Unsigned32) and Int64(RValue.Unsigned32));
        vtInteger: AssignInt64(Result, Int64(LValue.Unsigned32) and Int64(RValue.Signed32));
        vtNativeInt: AssignInt64(Result, Int64(LValue.Unsigned32) and Int64(RValue.NativeInt));
        vtNativeUInt: AssignInt64(Result, Int64(LValue.Unsigned32) and Int64(RValue.NativeUInt));
        vtInt64: AssignInt64(Result, Int64(LValue.Unsigned32) and RValue.Signed64);
        vtSingle: AssignSingle(Result, LValue.Unsigned32 and Round(RValue.Float32));
        vtDouble: AssignDouble(Result, LValue.Unsigned32 and Round(RValue.Float64));
        vtExtended: AssignExtended(Result, LValue.Unsigned32 and Round(RValue.Float80));
      end;
    vtInteger:
      case RValue.ValueType of
        vtByte: AssignInt64(Result, Int64(LValue.Signed32) and Int64(RValue.Unsigned8));
        vtShortint: AssignInt64(Result, Int64(LValue.Signed32) and Int64(RValue.Signed8));
        vtWord: AssignInt64(Result, Int64(LValue.Signed32) and Int64(RValue.Unsigned16));
        vtSmallint: AssignInt64(Result, Int64(LValue.Signed32) and Int64(RValue.Signed16));
        vtLongWord: AssignInt64(Result, Int64(LValue.Signed32) and Int64(RValue.Unsigned32));
        vtInteger: AssignInt64(Result, Int64(LValue.Signed32) and Int64(RValue.Signed32));
        vtNativeInt: AssignInt64(Result, Int64(LValue.Signed32) and Int64(RValue.NativeInt));
        vtNativeUInt: AssignInt64(Result, Int64(LValue.Signed32) and Int64(RValue.NativeUInt));
        vtInt64: AssignInt64(Result, Int64(LValue.Signed32) and RValue.Signed64);
        vtSingle: AssignSingle(Result, LValue.Signed32 and Round(RValue.Float32));
        vtDouble: AssignDouble(Result, LValue.Signed32 and Round(RValue.Float64));
        vtExtended: AssignExtended(Result, LValue.Signed32 and Round(RValue.Float80));
      end;
    vtNativeInt:
      case RValue.ValueType of
        vtByte: AssignInt64(Result, Int64(LValue.NativeInt) and Int64(RValue.Unsigned8));
        vtShortint: AssignInt64(Result, Int64(LValue.NativeInt) and Int64(RValue.Signed8));
        vtWord: AssignInt64(Result, Int64(LValue.NativeInt) and Int64(RValue.Unsigned16));
        vtSmallint: AssignInt64(Result, Int64(LValue.NativeInt) and Int64(RValue.Signed16));
        vtLongWord: AssignInt64(Result, Int64(LValue.NativeInt) and Int64(RValue.Unsigned32));
        vtInteger: AssignInt64(Result, Int64(LValue.NativeInt) and Int64(RValue.Signed32));
        vtNativeInt: AssignInt64(Result, Int64(LValue.NativeInt) and Int64(RValue.NativeInt));
        vtNativeUInt: AssignInt64(Result, Int64(LValue.NativeInt) and Int64(RValue.NativeUInt));
        vtInt64: AssignInt64(Result, Int64(LValue.NativeInt) and RValue.Signed64);
        vtSingle: AssignSingle(Result, LValue.NativeInt and Round(RValue.Float32));
        vtDouble: AssignDouble(Result, LValue.NativeInt and Round(RValue.Float64));
        vtExtended: AssignExtended(Result, LValue.NativeInt and Round(RValue.Float80));
      end;
    vtNativeUInt:
      case RValue.ValueType of
        vtByte: AssignInt64(Result, Int64(LValue.NativeUInt) and Int64(RValue.Unsigned8));
        vtShortint: AssignInt64(Result, Int64(LValue.NativeUInt) and Int64(RValue.Signed8));
        vtWord: AssignInt64(Result, Int64(LValue.NativeUInt) and Int64(RValue.Unsigned16));
        vtSmallint: AssignInt64(Result, Int64(LValue.NativeUInt) and Int64(RValue.Signed16));
        vtLongWord: AssignInt64(Result, Int64(LValue.NativeUInt) and Int64(RValue.Unsigned32));
        vtInteger: AssignInt64(Result, Int64(LValue.NativeUInt) and Int64(RValue.Signed32));
        vtNativeInt: AssignInt64(Result, Int64(LValue.NativeUInt) and Int64(RValue.NativeInt));
        vtNativeUInt: AssignInt64(Result, Int64(LValue.NativeUInt) and Int64(RValue.NativeUInt));
        vtInt64: AssignInt64(Result, Int64(LValue.NativeUInt) and RValue.Signed64);
        vtSingle: AssignSingle(Result, LValue.NativeUInt and Round(RValue.Float32));
        vtDouble: AssignDouble(Result, LValue.NativeUInt and Round(RValue.Float64));
        vtExtended: AssignExtended(Result, LValue.NativeUInt and Round(RValue.Float80));
      end;
    vtInt64:
      case RValue.ValueType of
        vtByte: AssignInt64(Result, Int64(LValue.Signed64) and Int64(RValue.Unsigned8));
        vtShortint: AssignInt64(Result, Int64(LValue.Signed64) and Int64(RValue.Signed8));
        vtWord: AssignInt64(Result, Int64(LValue.Signed64) and Int64(RValue.Unsigned16));
        vtSmallint: AssignInt64(Result, Int64(LValue.Signed64) and Int64(RValue.Signed16));
        vtLongWord: AssignInt64(Result, Int64(LValue.Signed64) and Int64(RValue.Unsigned32));
        vtInteger: AssignInt64(Result, Int64(LValue.Signed64) and Int64(RValue.Signed32));
        vtNativeInt: AssignInt64(Result, Int64(LValue.Signed64) and Int64(RValue.NativeInt));
        vtNativeUInt: AssignInt64(Result, Int64(LValue.Signed64) and Int64(RValue.NativeUInt));
        vtInt64: AssignInt64(Result, Int64(LValue.Signed64) and RValue.Signed64);
        vtSingle: AssignSingle(Result, LValue.Signed64 and Round(RValue.Float32));
        vtDouble: AssignDouble(Result, LValue.Signed64 and Round(RValue.Float64));
        vtExtended: AssignExtended(Result, LValue.Signed64 and Round(RValue.Float80));
      end;
    vtSingle:
      case RValue.ValueType of
        vtByte: AssignSingle(Result, Round(LValue.Float32) and RValue.Unsigned8);
        vtShortint: AssignSingle(Result, Round(LValue.Float32) and RValue.Signed8);
        vtWord: AssignSingle(Result, Round(LValue.Float32) and RValue.Unsigned16);
        vtSmallint: AssignSingle(Result, Round(LValue.Float32) and RValue.Signed16);
        vtLongWord: AssignSingle(Result, Round(LValue.Float32) and RValue.Unsigned32);
        vtInteger: AssignSingle(Result, Round(LValue.Float32) and RValue.Signed32);
        vtNativeInt: AssignSingle(Result, Round(LValue.Float32) and RValue.NativeInt);
        vtNativeUInt: AssignSingle(Result, Round(LValue.Float32) and RValue.NativeUInt);
        vtInt64: AssignSingle(Result, Round(LValue.Float32) and RValue.Signed64);
        vtSingle: AssignSingle(Result, Round(LValue.Float32) and Round(RValue.Float32));
        vtDouble: AssignDouble(Result, Round(LValue.Float32) and Round(RValue.Float64));
        vtExtended: AssignExtended(Result, Round(LValue.Float32) and Round(RValue.Float80));
      end;
    vtDouble:
      case RValue.ValueType of
        vtByte: AssignDouble(Result, Round(LValue.Float64) and RValue.Unsigned8);
        vtShortint: AssignDouble(Result, Round(LValue.Float64) and RValue.Signed8);
        vtWord: AssignDouble(Result, Round(LValue.Float64) and RValue.Unsigned16);
        vtSmallint: AssignDouble(Result, Round(LValue.Float64) and RValue.Signed16);
        vtLongWord: AssignDouble(Result, Round(LValue.Float64) and RValue.Unsigned32);
        vtInteger: AssignDouble(Result, Round(LValue.Float64) and RValue.Signed32);
        vtNativeInt: AssignDouble(Result, Round(LValue.Float64) and RValue.NativeInt);
        vtNativeUInt: AssignDouble(Result, Round(LValue.Float64) and RValue.NativeUInt);
        vtInt64: AssignDouble(Result, Round(LValue.Float64) and RValue.Signed64);
        vtSingle: AssignDouble(Result, Round(LValue.Float64) and Round(RValue.Float32));
        vtDouble: AssignDouble(Result, Round(LValue.Float64) and Round(RValue.Float64));
        vtExtended: AssignExtended(Result, Round(LValue.Float64) and Round(RValue.Float80));
      end;
    vtExtended:
      case RValue.ValueType of
        vtByte: AssignExtended(Result, Round(LValue.Float80) and RValue.Unsigned8);
        vtShortint: AssignExtended(Result, Round(LValue.Float80) and RValue.Signed8);
        vtWord: AssignExtended(Result, Round(LValue.Float80) and RValue.Unsigned16);
        vtSmallint: AssignExtended(Result, Round(LValue.Float80) and RValue.Signed16);
        vtLongWord: AssignExtended(Result, Round(LValue.Float80) and RValue.Unsigned32);
        vtInteger: AssignExtended(Result, Round(LValue.Float80) and RValue.Signed32);
        vtNativeInt: AssignExtended(Result, Round(LValue.Float80) and RValue.NativeInt);
        vtNativeUInt: AssignExtended(Result, Round(LValue.Float80) and RValue.NativeUInt);
        vtInt64: AssignExtended(Result, Round(LValue.Float80) and RValue.Signed64);
        vtSingle: AssignExtended(Result, Round(LValue.Float80) and Round(RValue.Float32));
        vtDouble: AssignExtended(Result, Round(LValue.Float80) and Round(RValue.Float64));
        vtExtended: AssignExtended(Result, Round(LValue.Float80) and Round(RValue.Float80));
      end;
  end;
end;

function TMethod.BelowMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const LValue, RValue: TValue): TValue;
var
  P: TParser;
begin
  Check(LValue.ValueType);
  Check(RValue.ValueType);
  P := TParser(FParser);
  Result := EmptyValue;
  case LValue.ValueType of
    vtByte:
      case RValue.ValueType of
        vtByte:
          if LValue.Unsigned8 < RValue.Unsigned8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtShortint:
          if Int64(LValue.Unsigned8) < RValue.Signed8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtWord:
          if LValue.Unsigned8 < RValue.Unsigned16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSmallint:
          if LValue.Unsigned8 < RValue.Signed16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtLongWord:
          if LValue.Unsigned8 < RValue.Unsigned32 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInteger:
          if LValue.Unsigned8 < RValue.Signed32 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeInt:
          if LValue.Unsigned8 < RValue.NativeInt then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeUInt:
          if LValue.Unsigned8 < RValue.NativeUInt then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInt64:
          if LValue.Unsigned8 < RValue.Signed64 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSingle:
          if Below(LValue.Unsigned8, RValue.Float32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtDouble:
          if Below(LValue.Unsigned8, RValue.Float64) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtExtended:
          if Below(LValue.Unsigned8, RValue.Float80) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
      end;
    vtShortint:
      case RValue.ValueType of
        vtByte:
          if LValue.Signed8 < Int64(RValue.Unsigned8) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtShortint:
          if LValue.Signed8 < RValue.Signed8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtWord:
          if LValue.Signed8 < Int64(RValue.Unsigned16) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSmallint:
          if LValue.Signed8 < RValue.Signed16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtLongWord:
          if LValue.Signed8 < Int64(RValue.Unsigned32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInteger:
          if LValue.Signed8 < RValue.Signed32 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeInt:
          if LValue.Signed8 < RValue.NativeInt then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeUInt:
          if LValue.Signed8 < Int64(RValue.NativeUInt) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInt64:
          if LValue.Signed8 < RValue.Signed64 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSingle:
          if Below(LValue.Signed8, RValue.Float32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtDouble:
          if Below(LValue.Signed8, RValue.Float64) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtExtended:
          if Below(LValue.Signed8, RValue.Float80) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
      end;
    vtWord:
      case RValue.ValueType of
        vtByte:
          if LValue.Unsigned16 < RValue.Unsigned8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtShortint:
          if Int64(LValue.Unsigned16) < RValue.Signed8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtWord:
          if LValue.Unsigned16 < RValue.Unsigned16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSmallint:
          if Int64(LValue.Unsigned16) < RValue.Signed16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtLongWord:
          if LValue.Unsigned16 < RValue.Unsigned32 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInteger:
          if LValue.Unsigned16 < RValue.Signed32 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeInt:
          if LValue.Unsigned16 < RValue.NativeInt then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeUInt:
          if LValue.Unsigned16 < RValue.NativeUInt then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInt64:
          if LValue.Unsigned16 < RValue.Signed64 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSingle:
          if Below(LValue.Unsigned16, RValue.Float32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtDouble:
          if Below(LValue.Unsigned16, RValue.Float64) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtExtended:
          if Below(LValue.Unsigned16, RValue.Float80) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
      end;
    vtSmallint:
      case RValue.ValueType of
        vtByte:
          if LValue.Signed16 < RValue.Unsigned8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtShortint:
          if LValue.Signed16 < RValue.Signed8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtWord:
          if LValue.Signed16 < Int64(RValue.Unsigned16) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSmallint:
          if LValue.Signed16 < RValue.Signed16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtLongWord:
          if LValue.Signed16 < Int64(RValue.Unsigned32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInteger:
          if LValue.Signed16 < RValue.Signed32 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeInt:
          if LValue.Signed16 < RValue.NativeInt then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeUInt:
          if LValue.Signed16 < Int64(RValue.NativeUInt) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInt64:
          if LValue.Signed16 < RValue.Signed64 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSingle:
          if Below(LValue.Signed16, RValue.Float32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtDouble:
          if Below(LValue.Signed16, RValue.Float64) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtExtended:
          if Below(LValue.Signed16, RValue.Float80) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
      end;
    vtLongWord:
      case RValue.ValueType of
        vtByte:
          if LValue.Unsigned32 < RValue.Unsigned8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtShortint:
          if Int64(LValue.Unsigned32) < RValue.Signed8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtWord:
          if LValue.Unsigned32 < RValue.Unsigned16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSmallint:
          if Int64(LValue.Unsigned32) < RValue.Signed16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtLongWord:
          if LValue.Unsigned32 < RValue.Unsigned32 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInteger:
          if Int64(LValue.Unsigned32) < RValue.Signed32 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeInt:
          if Int64(LValue.Unsigned32) < RValue.NativeInt then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeUInt:
          if LValue.Unsigned32 < RValue.NativeUInt then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInt64:
          if LValue.Unsigned32 < RValue.Signed64 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSingle:
          if Below(LValue.Unsigned32, RValue.Float32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtDouble:
          if Below(LValue.Unsigned32, RValue.Float64) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtExtended:
          if Below(LValue.Unsigned32, RValue.Float80) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
      end;
    vtInteger:
      case RValue.ValueType of
        vtByte:
          if LValue.Signed32 < RValue.Unsigned8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtShortint:
          if LValue.Signed32 < RValue.Signed8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtWord:
          if LValue.Signed32 < RValue.Unsigned16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSmallint:
          if LValue.Signed32 < RValue.Signed16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtLongWord:
          if LValue.Signed32 < Int64(RValue.Unsigned32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInteger:
          if LValue.Signed32 < RValue.Signed32 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeInt:
          if LValue.Signed32 < RValue.NativeInt then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeUInt:
          if LValue.Signed32 < Int64(RValue.NativeUInt) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInt64:
          if LValue.Signed32 < RValue.Signed64 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSingle:
          if Below(LValue.Signed32, RValue.Float32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtDouble:
          if Below(LValue.Signed32, RValue.Float64) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtExtended:
          if Below(LValue.Signed32, RValue.Float80) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
      end;
    vtNativeInt:
      case RValue.ValueType of
        vtByte:
          if LValue.NativeInt < RValue.Unsigned8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtShortint:
          if LValue.NativeInt < RValue.Signed8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtWord:
          if LValue.NativeInt < RValue.Unsigned16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSmallint:
          if LValue.NativeInt < RValue.Signed16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtLongWord:
          if LValue.NativeInt < Int64(RValue.Unsigned32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInteger:
          if LValue.NativeInt < RValue.Signed32 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeInt:
          if LValue.NativeInt < RValue.NativeInt then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeUInt:
          if LValue.NativeInt < Int64(RValue.NativeUInt) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInt64:
          if LValue.NativeInt < RValue.Signed64 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSingle:
          if Below(LValue.NativeInt, RValue.Float32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtDouble:
          if Below(LValue.NativeInt, RValue.Float64) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtExtended:
          if Below(LValue.NativeInt, RValue.Float80) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
      end;
    vtNativeUInt:
      case RValue.ValueType of
        vtByte:
          if LValue.NativeUInt < RValue.Unsigned8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtShortint:
          if Int64(LValue.NativeUInt) < RValue.Signed8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtWord:
          if LValue.NativeUInt < RValue.Unsigned16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSmallint:
          if Int64(LValue.NativeUInt) < RValue.Signed16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtLongWord:
          if LValue.NativeUInt < RValue.Unsigned32 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInteger:
          if Int64(LValue.NativeUInt) < RValue.Signed32 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeInt:
          if Int64(LValue.NativeUInt) < RValue.NativeInt then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeUInt:
          if LValue.NativeUInt < RValue.NativeUInt then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInt64:
          if LValue.NativeUInt < RValue.Signed64 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSingle:
          if Below(LValue.NativeUInt, RValue.Float32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtDouble:
          if Below(LValue.NativeUInt, RValue.Float64) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtExtended:
          if Below(LValue.NativeUInt, RValue.Float80) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
      end;
    vtInt64:
      case RValue.ValueType of
        vtByte:
          if LValue.Signed64 < RValue.Unsigned8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtShortint:
          if LValue.Signed64 < RValue.Signed8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtWord:
          if LValue.Signed64 < RValue.Unsigned16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSmallint:
          if LValue.Signed64 < RValue.Signed16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtLongWord:
          if LValue.Signed64 < RValue.Unsigned32 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInteger:
          if LValue.Signed64 < RValue.Signed32 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeInt:
          if LValue.Signed64 < RValue.NativeInt then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeUInt:
          if LValue.Signed64 < RValue.NativeUInt then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInt64:
          if LValue.Signed64 < RValue.Signed64 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSingle:
          if Below(LValue.Signed64, RValue.Float32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtDouble:
          if Below(LValue.Signed64, RValue.Float64) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtExtended:
          if Below(LValue.Signed64, RValue.Float80) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
      end;
    vtSingle:
      case RValue.ValueType of
        vtByte:
          if Below(LValue.Float32, RValue.Unsigned8) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtShortint:
          if Below(LValue.Float32, RValue.Signed8) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtWord:
          if Below(LValue.Float32, RValue.Unsigned16) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSmallint:
          if Below(LValue.Float32, RValue.Signed16) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtLongWord:
          if Below(LValue.Float32, RValue.Unsigned32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInteger:
          if Below(LValue.Float32, RValue.Signed32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeInt:
          if Below(LValue.Float32, RValue.NativeInt) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeUInt:
          if Below(LValue.Float32, RValue.NativeUInt) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInt64:
          if Below(LValue.Float32, RValue.Signed64) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSingle:
          if Below(LValue.Float32, RValue.Float32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtDouble:
          if Below(LValue.Float32, RValue.Float64) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtExtended:
          if Below(LValue.Float32, RValue.Float80) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
      end;
    vtDouble:
      case RValue.ValueType of
        vtByte:
          if Below(LValue.Float64, RValue.Unsigned8) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtShortint:
          if Below(LValue.Float64, RValue.Signed8) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtWord:
          if Below(LValue.Float64, RValue.Unsigned16) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSmallint:
          if Below(LValue.Float64, RValue.Signed16) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtLongWord:
          if Below(LValue.Float64, RValue.Unsigned32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInteger:
          if Below(LValue.Float64, RValue.Signed32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeInt:
          if Below(LValue.Float64, RValue.NativeInt) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeUInt:
          if Below(LValue.Float64, RValue.NativeUInt) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInt64:
          if Below(LValue.Float64, RValue.Signed64) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSingle:
          if Below(LValue.Float64, RValue.Float32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtDouble:
          if Below(LValue.Float64, RValue.Float64) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtExtended:
          if Below(LValue.Float64, RValue.Float80) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
      end;
    vtExtended:
      case RValue.ValueType of
        vtByte:
          if Below(LValue.Float80, RValue.Unsigned8) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtShortint:
          if Below(LValue.Float80, RValue.Signed8) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtWord:
          if Below(LValue.Float80, RValue.Unsigned16) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSmallint:
          if Below(LValue.Float80, RValue.Signed16) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtLongWord:
          if Below(LValue.Float80, RValue.Unsigned32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInteger:
          if Below(LValue.Float80, RValue.Signed32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeInt:
          if Below(LValue.Float80, RValue.NativeInt) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeUInt:
          if Below(LValue.Float80, RValue.NativeUInt) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInt64:
          if Below(LValue.Float80, RValue.Signed64) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSingle:
          if Below(LValue.Float80, RValue.Float32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtDouble:
          if Below(LValue.Float80, RValue.Float64) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtExtended:
          if Below(LValue.Float80, RValue.Float80) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
      end;
  end;
  Result.ValueType := vtInteger;
end;

function TMethod.BelowOrEqualMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const LValue, RValue: TValue): TValue;
var
  P: TParser;
begin
  Check(LValue.ValueType);
  Check(RValue.ValueType);
  P := TParser(FParser);
  Result := EmptyValue;
  case LValue.ValueType of
    vtByte:
      case RValue.ValueType of
        vtByte:
          if LValue.Unsigned8 <= RValue.Unsigned8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtShortint:
          if Int64(LValue.Unsigned8) <= RValue.Signed8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtWord:
          if LValue.Unsigned8 <= RValue.Unsigned16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSmallint:
          if LValue.Unsigned8 <= RValue.Signed16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtLongWord:
          if LValue.Unsigned8 <= RValue.Unsigned32 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInteger:
          if LValue.Unsigned8 <= RValue.Signed32 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeInt:
          if LValue.Unsigned8 <= RValue.NativeInt then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeUInt:
          if LValue.Unsigned8 <= RValue.NativeUInt then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInt64:
          if LValue.Unsigned8 <= RValue.Signed64 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSingle:
          if BelowOrEqual(LValue.Unsigned8, RValue.Float32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtDouble:
          if BelowOrEqual(LValue.Unsigned8, RValue.Float64) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtExtended:
          if BelowOrEqual(LValue.Unsigned8, RValue.Float80) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
      end;
    vtShortint:
      case RValue.ValueType of
        vtByte:
          if LValue.Signed8 <= Int64(RValue.Unsigned8) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtShortint:
          if LValue.Signed8 <= RValue.Signed8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtWord:
          if LValue.Signed8 <= Int64(RValue.Unsigned16) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSmallint:
          if LValue.Signed8 <= RValue.Signed16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtLongWord:
          if LValue.Signed8 <= Int64(RValue.Unsigned32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInteger:
          if LValue.Signed8 <= RValue.Signed32 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeInt:
          if LValue.Signed8 <= RValue.NativeInt then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeUInt:
          if LValue.Signed8 <= Int64(RValue.NativeUInt) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInt64:
          if LValue.Signed8 <= RValue.Signed64 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSingle:
          if BelowOrEqual(LValue.Signed8, RValue.Float32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtDouble:
          if BelowOrEqual(LValue.Signed8, RValue.Float64) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtExtended:
          if BelowOrEqual(LValue.Signed8, RValue.Float80) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
      end;
    vtWord:
      case RValue.ValueType of
        vtByte:
          if LValue.Unsigned16 <= RValue.Unsigned8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtShortint:
          if Int64(LValue.Unsigned16) <= RValue.Signed8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtWord:
          if LValue.Unsigned16 <= RValue.Unsigned16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSmallint:
          if Int64(LValue.Unsigned16) <= RValue.Signed16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtLongWord:
          if LValue.Unsigned16 <= RValue.Unsigned32 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInteger:
          if LValue.Unsigned16 <= RValue.Signed32 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeInt:
          if LValue.Unsigned16 <= RValue.NativeInt then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeUInt:
          if LValue.Unsigned16 <= RValue.NativeUInt then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInt64:
          if LValue.Unsigned16 <= RValue.Signed64 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSingle:
          if BelowOrEqual(LValue.Unsigned16, RValue.Float32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtDouble:
          if BelowOrEqual(LValue.Unsigned16, RValue.Float64) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtExtended:
          if BelowOrEqual(LValue.Unsigned16, RValue.Float80) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
      end;
    vtSmallint:
      case RValue.ValueType of
        vtByte:
          if LValue.Signed16 <= RValue.Unsigned8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtShortint:
          if LValue.Signed16 <= RValue.Signed8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtWord:
          if LValue.Signed16 <= Int64(RValue.Unsigned16) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSmallint:
          if LValue.Signed16 <= RValue.Signed16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtLongWord:
          if LValue.Signed16 <= Int64(RValue.Unsigned32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInteger:
          if LValue.Signed16 <= RValue.Signed32 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeInt:
          if LValue.Signed16 <= RValue.NativeInt then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeUInt:
          if LValue.Signed16 <= Int64(RValue.NativeUInt) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInt64:
          if LValue.Signed16 <= RValue.Signed64 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSingle:
          if BelowOrEqual(LValue.Signed16, RValue.Float32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtDouble:
          if BelowOrEqual(LValue.Signed16, RValue.Float64) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtExtended:
          if BelowOrEqual(LValue.Signed16, RValue.Float80) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
      end;
    vtLongWord:
      case RValue.ValueType of
        vtByte:
          if LValue.Unsigned32 <= RValue.Unsigned8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtShortint:
          if Int64(LValue.Unsigned32) <= RValue.Signed8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtWord:
          if LValue.Unsigned32 <= RValue.Unsigned16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSmallint:
          if Int64(LValue.Unsigned32) <= RValue.Signed16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtLongWord:
          if LValue.Unsigned32 <= RValue.Unsigned32 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInteger:
          if Int64(LValue.Unsigned32) <= RValue.Signed32 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeInt:
          if Int64(LValue.Unsigned32) <= RValue.NativeInt then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeUInt:
          if LValue.Unsigned32 <= RValue.NativeUInt then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInt64:
          if LValue.Unsigned32 <= RValue.Signed64 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSingle:
          if BelowOrEqual(LValue.Unsigned32, RValue.Float32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtDouble:
          if BelowOrEqual(LValue.Unsigned32, RValue.Float64) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtExtended:
          if BelowOrEqual(LValue.Unsigned32, RValue.Float80) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
      end;
    vtInteger:
      case RValue.ValueType of
        vtByte:
          if LValue.Signed32 <= RValue.Unsigned8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtShortint:
          if LValue.Signed32 <= RValue.Signed8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtWord:
          if LValue.Signed32 <= RValue.Unsigned16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSmallint:
          if LValue.Signed32 <= RValue.Signed16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtLongWord:
          if LValue.Signed32 <= Int64(RValue.Unsigned32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInteger:
          if LValue.Signed32 <= RValue.Signed32 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeInt:
          if LValue.Signed32 <= RValue.NativeInt then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeUInt:
          if LValue.Signed32 <= Int64(RValue.NativeUInt) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInt64:
          if LValue.Signed32 <= RValue.Signed64 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSingle:
          if BelowOrEqual(LValue.Signed32, RValue.Float32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtDouble:
          if BelowOrEqual(LValue.Signed32, RValue.Float64) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtExtended:
          if BelowOrEqual(LValue.Signed32, RValue.Float80) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
      end;
    vtNativeInt:
      case RValue.ValueType of
        vtByte:
          if LValue.NativeInt <= RValue.Unsigned8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtShortint:
          if LValue.NativeInt <= RValue.Signed8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtWord:
          if LValue.NativeInt <= RValue.Unsigned16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSmallint:
          if LValue.NativeInt <= RValue.Signed16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtLongWord:
          if LValue.NativeInt <= Int64(RValue.Unsigned32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInteger:
          if LValue.NativeInt <= RValue.Signed32 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeInt:
          if LValue.NativeInt <= RValue.NativeInt then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeUInt:
          if LValue.NativeInt <= Int64(RValue.NativeUInt) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInt64:
          if LValue.NativeInt <= RValue.Signed64 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSingle:
          if BelowOrEqual(LValue.NativeInt, RValue.Float32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtDouble:
          if BelowOrEqual(LValue.NativeInt, RValue.Float64) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtExtended:
          if BelowOrEqual(LValue.NativeInt, RValue.Float80) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
      end;
    vtNativeUInt:
      case RValue.ValueType of
        vtByte:
          if LValue.NativeUInt <= RValue.Unsigned8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtShortint:
          if Int64(LValue.NativeUInt) <= RValue.Signed8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtWord:
          if LValue.NativeUInt <= RValue.Unsigned16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSmallint:
          if Int64(LValue.NativeUInt) <= RValue.Signed16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtLongWord:
          if LValue.NativeUInt <= RValue.Unsigned32 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInteger:
          if Int64(LValue.NativeUInt) <= RValue.Signed32 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeInt:
          if Int64(LValue.NativeUInt) <= RValue.NativeInt then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeUInt:
          if LValue.NativeUInt <= RValue.NativeUInt then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInt64:
          if LValue.NativeUInt <= RValue.Signed64 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSingle:
          if BelowOrEqual(LValue.NativeUInt, RValue.Float32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtDouble:
          if BelowOrEqual(LValue.NativeUInt, RValue.Float64) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtExtended:
          if BelowOrEqual(LValue.NativeUInt, RValue.Float80) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
      end;
    vtInt64:
      case RValue.ValueType of
        vtByte:
          if LValue.Signed64 <= RValue.Unsigned8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtShortint:
          if LValue.Signed64 <= RValue.Signed8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtWord:
          if LValue.Signed64 <= RValue.Unsigned16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSmallint:
          if LValue.Signed64 <= RValue.Signed16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtLongWord:
          if LValue.Signed64 <= RValue.Unsigned32 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInteger:
          if LValue.Signed64 <= RValue.Signed32 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeInt:
          if LValue.Signed64 <= RValue.NativeInt then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeUInt:
          if LValue.Signed64 <= RValue.NativeUInt then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInt64:
          if LValue.Signed64 <= RValue.Signed64 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSingle:
          if BelowOrEqual(LValue.Signed64, RValue.Float32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtDouble:
          if BelowOrEqual(LValue.Signed64, RValue.Float64) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtExtended:
          if BelowOrEqual(LValue.Signed64, RValue.Float80) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
      end;
    vtSingle:
      case RValue.ValueType of
        vtByte:
          if BelowOrEqual(LValue.Float32, RValue.Unsigned8) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtShortint:
          if BelowOrEqual(LValue.Float32, RValue.Signed8) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtWord:
          if BelowOrEqual(LValue.Float32, RValue.Unsigned16) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSmallint:
          if BelowOrEqual(LValue.Float32, RValue.Signed16) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtLongWord:
          if BelowOrEqual(LValue.Float32, RValue.Unsigned32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInteger:
          if BelowOrEqual(LValue.Float32, RValue.Signed32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeInt:
          if BelowOrEqual(LValue.Float32, RValue.NativeInt) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeUInt:
          if BelowOrEqual(LValue.Float32, RValue.NativeUInt) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInt64:
          if BelowOrEqual(LValue.Float32, RValue.Signed64) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSingle:
          if BelowOrEqual(LValue.Float32, RValue.Float32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtDouble:
          if BelowOrEqual(LValue.Float32, RValue.Float64) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtExtended:
          if BelowOrEqual(LValue.Float32, RValue.Float80) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
      end;
    vtDouble:
      case RValue.ValueType of
        vtByte:
          if BelowOrEqual(LValue.Float64, RValue.Unsigned8) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtShortint:
          if BelowOrEqual(LValue.Float64, RValue.Signed8) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtWord:
          if BelowOrEqual(LValue.Float64, RValue.Unsigned16) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSmallint:
          if BelowOrEqual(LValue.Float64, RValue.Signed16) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtLongWord:
          if BelowOrEqual(LValue.Float64, RValue.Unsigned32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInteger:
          if BelowOrEqual(LValue.Float64, RValue.Signed32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeInt:
          if BelowOrEqual(LValue.Float64, RValue.NativeInt) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeUInt:
          if BelowOrEqual(LValue.Float64, RValue.NativeUInt) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInt64:
          if BelowOrEqual(LValue.Float64, RValue.Signed64) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSingle:
          if BelowOrEqual(LValue.Float64, RValue.Float32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtDouble:
          if BelowOrEqual(LValue.Float64, RValue.Float64) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtExtended:
          if BelowOrEqual(LValue.Float64, RValue.Float80) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
      end;
    vtExtended:
      case RValue.ValueType of
        vtByte:
          if BelowOrEqual(LValue.Float80, RValue.Unsigned8) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtShortint:
          if BelowOrEqual(LValue.Float80, RValue.Signed8) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtWord:
          if BelowOrEqual(LValue.Float80, RValue.Unsigned16) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSmallint:
          if BelowOrEqual(LValue.Float80, RValue.Signed16) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtLongWord:
          if BelowOrEqual(LValue.Float80, RValue.Unsigned32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInteger:
          if BelowOrEqual(LValue.Float80, RValue.Signed32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeInt:
          if BelowOrEqual(LValue.Float80, RValue.NativeInt) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeUInt:
          if BelowOrEqual(LValue.Float80, RValue.NativeUInt) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInt64:
          if BelowOrEqual(LValue.Float80, RValue.Signed64) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSingle:
          if BelowOrEqual(LValue.Float80, RValue.Float32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtDouble:
          if BelowOrEqual(LValue.Float80, RValue.Float64) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtExtended:
          if BelowOrEqual(LValue.Float80, RValue.Float80) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
      end;
  end;
  Result.ValueType := vtInteger;
end;

constructor TMethod.Create(const AParser: TObject);
begin
  inherited;
  FContainer := TVariableContainer.Create;
end;

function TMethod.DeleteMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const PA: TParameterArray): TValue;
var
  P: TCustomParser;
  Parameter: TParameter;
  S: string;
  BFunction: PFunction;
begin
  Check(AFunction, PA, AFunction.Method.Parameter.Count);
  P := TCustomParser(FParser);
  Parameter := GetParameter(P, Header, PA[0]);
  Check(FParser, AFunction, 0, Parameter.THandle, True);
  S := Trim(Parameter.Text);
  BFunction := P.FindFunction(S);
  if Assigned(BFunction) and (BFunction.Method.MethodType = mtVariable) then
  begin
    P.DeleteFunction(BFunction.Handle^);
    FContainer.Delete(S);
    Result := P.PositiveValue;
  end
  else
    Result := P.NegativeValue;
end;

function TMethod.DerivMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const PA: TParameterArray): TValue;
const
  Delta = 0.001;
var
  P: TParser;
  BFunction: PFunction;
  Handle: NativeInt;
  E: Extended;
  AValue, BValue, CValue: TValue;
  Script: TScript;
begin
  Enter(MethodSync);
  try
    Check(AFunction, PA, DerivParameterMinCount, DerivParameterMaxCount);
    Check(FParser, AFunction, 0, PA[0].THandle, True);
    Check(FParser, AFunction, 1, PA[1].THandle, True);
    P := TParser(FParser);
    BFunction := P.FindFunction(PA[1].Text);
    repeat
      if not Assigned(BFunction) or (BFunction.Method.MethodType <> mtVariable) then
      begin
        Result := EmptyValue;
        Break;
      end;
      while P.GetRedirect(Header.RedirectCategory, BFunction.Handle^, Handle) do
      begin
        BFunction := P.GetFunction(Handle);
        if not Assigned(BFunction) then
        begin
          Result := EmptyValue;
          Break;
        end;
      end;
      if Length(PA) > 2 then
        E := GetExtended(PA[2].Value)
      else
        E := Delta;
      case BFunction.Method.Variable.VariableType of
        vtValue: BValue := BFunction.Method.Variable.Variable^;
        vtValueRef: BValue := MakeValue(BFunction.Method.Variable.VariableRef);
      end;
      try
        case BFunction.Method.Variable.VariableType of
          vtValue:
            BFunction.Method.Variable.Variable^ := Operation(BValue, MakeExtended(E), otSubtract);
          vtValueRef:
            AssignValue(BFunction.Method.Variable.VariableRef, Operation(BValue, MakeExtended(E), otSubtract));
        end;
        Script := nil;
        try
          P.StringToScript(DequoteDouble(PA[0].Text, P.FData.FA[P.DerivHandle].Name, P.Bracket), Script);
          P.SetRedirectCategory(Script, Header.RedirectCategory);
          AValue := P.ExecuteScript(Script)^;
          case BFunction.Method.Variable.VariableType of
            vtValue:
              BFunction.Method.Variable.Variable^ := Operation(BValue, MakeExtended(E), otAdd);
            vtValueRef:
              AssignValue(BFunction.Method.Variable.VariableRef, Operation(BValue, MakeExtended(E), otAdd));
          end;
          CValue := P.ExecuteScript(Script)^;
        finally
          Script := nil;
        end;
      finally
        case BFunction.Method.Variable.VariableType of
          vtValue: BFunction.Method.Variable.Variable^ := BValue;
          vtValueRef: AssignValue(BFunction.Method.Variable.VariableRef, BValue);
        end;
      end;
      Result := Operation(Operation(CValue, AValue, otSubtract), Operation(MakeExtended(E), MakeByte(2), otMultiply), otDivide);
    until True;
  finally
    Leave(MethodSync);
  end;
end;

destructor TMethod.Destroy;
begin
  FContainer.Free;
  inherited;
end;

function TMethod.DivideMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const LValue, RValue: TValue): TValue;
begin
  Result := Operation(LValue, RValue, otDivide);
end;

function TMethod.EnsureRangeMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const PA: TParameterArray): TValue;
var
  AValue, BValue, CValue: TValue;
begin
  Check(AFunction, PA, AFunction.Method.Parameter.Count);
  Check(FParser, AFunction, PA, False);
  AValue := PA[0].Value;
  BValue := PA[1].Value;
  CValue := PA[2].Value;
  if (AValue.ValueType in FloatTypeSet) or (BValue.ValueType in FloatTypeSet) then
    AssignExtended(Result, EnsureRange(GetExtended(AValue), GetExtended(BValue), GetExtended(CValue)))
  else
    AssignInt64(Result, EnsureRange(GetInt64(AValue), GetInt64(BValue), GetInt64(CValue)));
end;

function TMethod.EqualMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const LValue, RValue: TValue): TValue;
var
  P: TParser;
begin
  Check(LValue.ValueType);
  Check(RValue.ValueType);
  P := TParser(FParser);
  Result := EmptyValue;
  case LValue.ValueType of
    vtByte:
      case RValue.ValueType of
        vtByte:
          if LValue.Unsigned8 = RValue.Unsigned8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtShortint:
          if Int64(LValue.Unsigned8) = RValue.Signed8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtWord:
          if LValue.Unsigned8 = RValue.Unsigned16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSmallint:
          if LValue.Unsigned8 = RValue.Signed16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtLongWord:
          if LValue.Unsigned8 = RValue.Unsigned32 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInteger:
          if LValue.Unsigned8 = RValue.Signed32 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeInt:
          if LValue.Unsigned8 = RValue.NativeInt then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeUInt:
          if LValue.Unsigned8 = RValue.NativeUInt then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInt64:
          if LValue.Unsigned8 = RValue.Signed64 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSingle:
          if Equal(LValue.Unsigned8, RValue.Float32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtDouble:
          if Equal(LValue.Unsigned8, RValue.Float64) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtExtended:
          if Equal(LValue.Unsigned8, RValue.Float80) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
      end;
    vtShortint:
      case RValue.ValueType of
        vtByte:
          if LValue.Signed8 = Int64(RValue.Unsigned8) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtShortint:
          if LValue.Signed8 = RValue.Signed8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtWord:
          if LValue.Signed8 = Int64(RValue.Unsigned16) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSmallint:
          if LValue.Signed8 = RValue.Signed16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtLongWord:
          if LValue.Signed8 = Int64(RValue.Unsigned32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInteger:
          if LValue.Signed8 = RValue.Signed32 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeInt:
          if LValue.Signed8 = RValue.NativeInt then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeUInt:
          if LValue.Signed8 = Int64(RValue.NativeUInt) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInt64:
          if LValue.Signed8 = RValue.Signed64 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSingle:
          if Equal(LValue.Signed8, RValue.Float32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtDouble:
          if Equal(LValue.Signed8, RValue.Float64) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtExtended:
          if Equal(LValue.Signed8, RValue.Float80) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
      end;
    vtWord:
      case RValue.ValueType of
        vtByte:
          if LValue.Unsigned16 = RValue.Unsigned8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtShortint:
          if Int64(LValue.Unsigned16) = RValue.Signed8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtWord:
          if LValue.Unsigned16 = RValue.Unsigned16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSmallint:
          if Int64(LValue.Unsigned16) = RValue.Signed16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtLongWord:
          if LValue.Unsigned16 = RValue.Unsigned32 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInteger:
          if LValue.Unsigned16 = RValue.Signed32 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeInt:
          if LValue.Unsigned16 = RValue.NativeInt then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeUInt:
          if LValue.Unsigned16 = RValue.NativeUInt then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInt64:
          if LValue.Unsigned16 = RValue.Signed64 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSingle:
          if Equal(LValue.Unsigned16, RValue.Float32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtDouble:
          if Equal(LValue.Unsigned16, RValue.Float64) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtExtended:
          if Equal(LValue.Unsigned16, RValue.Float80) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
      end;
    vtSmallint:
      case RValue.ValueType of
        vtByte:
          if LValue.Signed16 = RValue.Unsigned8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtShortint:
          if LValue.Signed16 = RValue.Signed8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtWord:
          if LValue.Signed16 = Int64(RValue.Unsigned16) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSmallint:
          if LValue.Signed16 = RValue.Signed16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtLongWord:
          if LValue.Signed16 = Int64(RValue.Unsigned32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInteger:
          if LValue.Signed16 = RValue.Signed32 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeInt:
          if LValue.Signed16 = RValue.NativeInt then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeUInt:
          if LValue.Signed16 = Int64(RValue.NativeUInt) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInt64:
          if LValue.Signed16 = RValue.Signed64 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSingle:
          if Equal(LValue.Signed16, RValue.Float32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtDouble:
          if Equal(LValue.Signed16, RValue.Float64) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtExtended:
          if Equal(LValue.Signed16, RValue.Float80) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
      end;
    vtLongWord:
      case RValue.ValueType of
        vtByte:
          if LValue.Unsigned32 = RValue.Unsigned8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtShortint:
          if Int64(LValue.Unsigned32) = RValue.Signed8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtWord:
          if LValue.Unsigned32 = RValue.Unsigned16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSmallint:
          if Int64(LValue.Unsigned32) = RValue.Signed16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtLongWord:
          if LValue.Unsigned32 = RValue.Unsigned32 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInteger:
          if Int64(LValue.Unsigned32) = RValue.Signed32 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeInt:
          if Int64(LValue.Unsigned32) = RValue.NativeInt then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeUInt:
          if LValue.Unsigned32 = RValue.NativeUInt then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInt64:
          if LValue.Unsigned32 = RValue.Signed64 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSingle:
          if Equal(LValue.Unsigned32, RValue.Float32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtDouble:
          if Equal(LValue.Unsigned32, RValue.Float64) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtExtended:
          if Equal(LValue.Unsigned32, RValue.Float80) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
      end;
    vtInteger:
      case RValue.ValueType of
        vtByte:
          if LValue.Signed32 = RValue.Unsigned8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtShortint:
          if LValue.Signed32 = RValue.Signed8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtWord:
          if LValue.Signed32 = RValue.Unsigned16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSmallint:
          if LValue.Signed32 = RValue.Signed16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtLongWord:
          if LValue.Signed32 = Int64(RValue.Unsigned32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInteger:
          if LValue.Signed32 = RValue.Signed32 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeInt:
          if LValue.Signed32 = RValue.NativeInt then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeUInt:
          if LValue.Signed32 = Int64(RValue.NativeUInt) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInt64:
          if LValue.Signed32 = RValue.Signed64 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSingle:
          if Equal(LValue.Signed32, RValue.Float32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtDouble:
          if Equal(LValue.Signed32, RValue.Float64) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtExtended:
          if Equal(LValue.Signed32, RValue.Float80) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
      end;
    vtNativeInt:
      case RValue.ValueType of
        vtByte:
          if LValue.NativeInt = RValue.Unsigned8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtShortint:
          if LValue.NativeInt = RValue.Signed8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtWord:
          if LValue.NativeInt = RValue.Unsigned16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSmallint:
          if LValue.NativeInt = RValue.Signed16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtLongWord:
          if LValue.NativeInt = Int64(RValue.Unsigned32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInteger:
          if LValue.NativeInt = RValue.Signed32 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeInt:
          if LValue.NativeInt = RValue.NativeInt then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeUInt:
          if LValue.NativeInt = Int64(RValue.NativeUInt) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInt64:
          if LValue.NativeInt = RValue.Signed64 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSingle:
          if Equal(LValue.NativeInt, RValue.Float32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtDouble:
          if Equal(LValue.NativeInt, RValue.Float64) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtExtended:
          if Equal(LValue.NativeInt, RValue.Float80) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
      end;
    vtNativeUInt:
      case RValue.ValueType of
        vtByte:
          if LValue.NativeUInt = RValue.Unsigned8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtShortint:
          if Int64(LValue.NativeUInt) = RValue.Signed8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtWord:
          if LValue.NativeUInt = RValue.Unsigned16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSmallint:
          if Int64(LValue.NativeUInt) = RValue.Signed16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtLongWord:
          if LValue.NativeUInt = RValue.Unsigned32 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInteger:
          if Int64(LValue.NativeUInt) = RValue.Signed32 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeInt:
          if Int64(LValue.NativeUInt) = RValue.NativeInt then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeUInt:
          if LValue.NativeUInt = RValue.NativeUInt then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInt64:
          if LValue.NativeUInt = RValue.Signed64 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSingle:
          if Equal(LValue.NativeUInt, RValue.Float32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtDouble:
          if Equal(LValue.NativeUInt, RValue.Float64) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtExtended:
          if Equal(LValue.NativeUInt, RValue.Float80) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
      end;
    vtInt64:
      case RValue.ValueType of
        vtByte:
          if LValue.Signed64 = RValue.Unsigned8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtShortint:
          if LValue.Signed64 = RValue.Signed8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtWord:
          if LValue.Signed64 = RValue.Unsigned16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSmallint:
          if LValue.Signed64 = RValue.Signed16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtLongWord:
          if LValue.Signed64 = RValue.Unsigned32 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInteger:
          if LValue.Signed64 = RValue.Signed32 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeInt:
          if LValue.Signed64 = RValue.NativeInt then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeUInt:
          if LValue.Signed64 = RValue.NativeUInt then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInt64:
          if LValue.Signed64 = RValue.Signed64 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSingle:
          if Equal(LValue.Signed64, RValue.Float32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtDouble:
          if Equal(LValue.Signed64, RValue.Float64) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtExtended:
          if Equal(LValue.Signed64, RValue.Float80) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
      end;
    vtSingle:
      case RValue.ValueType of
        vtByte:
          if Equal(LValue.Float32, RValue.Unsigned8) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtShortint:
          if Equal(LValue.Float32, RValue.Signed8) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtWord:
          if Equal(LValue.Float32, RValue.Unsigned16) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSmallint:
          if Equal(LValue.Float32, RValue.Signed16) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtLongWord:
          if Equal(LValue.Float32, RValue.Unsigned32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInteger:
          if Equal(LValue.Float32, RValue.Signed32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeInt:
          if Equal(LValue.Float32, RValue.NativeInt) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeUInt:
          if Equal(LValue.Float32, RValue.NativeUInt) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInt64:
          if Equal(LValue.Float32, RValue.Signed64) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSingle:
          if Equal(LValue.Float32, RValue.Float32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtDouble:
          if Equal(LValue.Float32, RValue.Float64) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtExtended:
          if Equal(LValue.Float32, RValue.Float80) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
      end;
    vtDouble:
      case RValue.ValueType of
        vtByte:
          if Equal(LValue.Float64, RValue.Unsigned8) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtShortint:
          if Equal(LValue.Float64, RValue.Signed8) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtWord:
          if Equal(LValue.Float64, RValue.Unsigned16) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSmallint:
          if Equal(LValue.Float64, RValue.Signed16) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtLongWord:
          if Equal(LValue.Float64, RValue.Unsigned32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInteger:
          if Equal(LValue.Float64, RValue.Signed32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeInt:
          if Equal(LValue.Float64, RValue.NativeInt) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeUInt:
          if Equal(LValue.Float64, RValue.NativeUInt) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInt64:
          if Equal(LValue.Float64, RValue.Signed64) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSingle:
          if Equal(LValue.Float64, RValue.Float32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtDouble:
          if Equal(LValue.Float64, RValue.Float64) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtExtended:
          if Equal(LValue.Float64, RValue.Float80) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
      end;
    vtExtended:
      case RValue.ValueType of
        vtByte:
          if Equal(LValue.Float80, RValue.Unsigned8) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtShortint:
          if Equal(LValue.Float80, RValue.Signed8) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtWord:
          if Equal(LValue.Float80, RValue.Unsigned16) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSmallint:
          if Equal(LValue.Float80, RValue.Signed16) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtLongWord:
          if Equal(LValue.Float80, RValue.Unsigned32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInteger:
          if Equal(LValue.Float80, RValue.Signed32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeInt:
          if Equal(LValue.Float80, RValue.NativeInt) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeUInt:
          if Equal(LValue.Float80, RValue.NativeUInt) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInt64:
          if Equal(LValue.Float80, RValue.Signed64) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSingle:
          if Equal(LValue.Float80, RValue.Float32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtDouble:
          if Equal(LValue.Float80, RValue.Float64) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtExtended:
          if Equal(LValue.Float80, RValue.Float80) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
      end;
  end;
  Result.ValueType := vtInteger;
end;

function TMethod.ExecuteMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const PA: TParameterArray): TValue;
var
  P: TCustomParser;
begin
  P := TCustomParser(FParser);
  Check(AFunction, PA, AFunction.Method.Parameter.Count);
  Check(FParser, AFunction, PA, False);
  GetParameter(P, Header, PA[0]);
  Result := AsValue(P, Header, PA[1]);
end;

function TMethod.ExitMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const PA: TParameterArray): TValue;
begin
  Check(AFunction, PA, AFunction.Method.Parameter.Count);
  Check(FParser, AFunction, PA, False);
  raise EParserExit.Create(PA[0].Value);
end;

function TMethod.FalseMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType): TValue;
begin
  Result := TParser(FParser).NegativeValue;
end;

function TMethod.FindMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const PA: TParameterArray): TValue;
var
  P: TCustomParser;
  Parameter: TParameter;
  S: string;
  BFunction: PFunction;
begin
  Check(AFunction, PA, AFunction.Method.Parameter.Count);
  P := TCustomParser(FParser);
  Parameter := GetParameter(P, Header, PA[0]);
  Check(FParser, AFunction, 0, Parameter.THandle, True);
  S := Trim(Parameter.Text);
  BFunction := P.FindFunction(S);
  if Assigned(BFunction) and (BFunction.Method.MethodType = mtVariable) then
    Result := P.PositiveValue
  else
    Result := P.NegativeValue;
end;

function TMethod.ForMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const PA: TParameterArray): TValue;
var
  P: TCustomParser;
  Parameter: TParameter;
  S: string;
  BFunction: PFunction;
  Variable: PFunctionVariable;
  Value: PValue;
  BType: PType;
begin
  Check(AFunction, PA, AFunction.Method.Parameter.Count);
  Check(FParser, AFunction, 1, PA[1].THandle, False);
  Check(FParser, AFunction, 2, PA[2].THandle, False);
  Check(FParser, AFunction, 3, PA[3].THandle, False);
  P := TCustomParser(FParser);
  Parameter := GetParameter(P, Header, PA[0]);
  Check(FParser, AFunction, 0, Parameter.THandle, True);
  S := Parameter.Text;
  BFunction := P.FindFunction(S);
  Value := nil;
  try
    if Assigned(BFunction) then
    begin
      Variable := @BFunction.Method.Variable;
      case Variable.VariableType of
        vtValue: Variable.Variable^ := AsValue(P, Header, PA[1]);
        vtValueRef: AssignValue(Variable.VariableRef, AsValue(P, Header, PA[1]));
      end;
    end
    else begin
      Parameter := GetParameter(P, Header, PA[1]);
      New(Value);
      Value^ := Parameter.Value;
      if P.GetType(Parameter.THandle, BType) then
        Value^ := Convert(Value^, BType.ValueType);
      P.AddVariable(S, Value^, True);
    end;
    Result := EmptyValue;
    while AsBoolean(P, Header, PA[2]) do
      AssignBoolean(Result, AsBoolean(P, Header, PA[3]) or GetBoolean(Result));
  finally
    if Assigned(Value) then
    begin
      P.DeleteVariable(Value^);
      Dispose(Value);
    end;
  end;
end;

function TMethod.GetEpsilonMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType): TValue;
begin
  AssignExtended(Result, Epsilon);
end;

function TMethod.GetMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const PA: TParameterArray): TValue;
var
  Parameter: TParameter;
  S: string;
  BFunction: PFunction;
  Variable: PFunctionVariable;
begin
  Check(AFunction, PA, AFunction.Method.Parameter.Count);
  Parameter := GetParameter(TCustomParser(FParser), Header, PA[0]);
  Check(FParser, AFunction, 0, Parameter.THandle, True);
  S := Trim(Parameter.Text);
  BFunction := TParser(FParser).FindFunction(S);
  if Assigned(BFunction) and (BFunction.Method.MethodType = mtVariable) then
  begin
    Variable := @BFunction.Method.Variable;
    case Variable.VariableType of
      vtValue: Result := Variable.Variable^;
      vtValueRef: Result := MakeValue(Variable.VariableRef);
    end;
  end
  else
    Result := EmptyValue;
end;

function TMethod.IfMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const PA: TParameterArray): TValue;
var
  P: TCustomParser;
begin
  Check(AFunction, PA, IfParameterMinCount, IfParameterMaxCount);
  Check(FParser, AFunction, PA, False);
  P := TCustomParser(FParser);
  if AsBoolean(P, Header, PA[0]) then
    Result := AsValue(P, Header, PA[1])
  else
    if Length(PA) > 2 then
      Result := AsValue(P, Header, PA[2])
    else
      Result := EmptyValue;
end;

function TMethod.IfThenMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const PA: TParameterArray): TValue;
var
  AValue, BValue, CValue: TValue;
begin
  Check(AFunction, PA, AFunction.Method.Parameter.Count);
  Check(FParser, AFunction, PA, False);
  AValue := PA[0].Value;
  BValue := PA[1].Value;
  CValue := PA[2].Value;
  if GetBoolean(AValue) then
    Result := BValue
  else
    Result := CValue;
end;

function TMethod.IsZeroMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const PA: TParameterArray): TValue;
var
  P: TParser;
  AValue: TValue;
  BValue: Double;
begin
  Check(AFunction, PA, IsZeroParameterMinCount, IsZeroParameterMaxCount);
  Check(FParser, AFunction, PA, False);
  P := TParser(FParser);
  AValue := PA[0].Value;
  if Length(PA) > 1 then
  begin
    BValue := GetExtended(PA[1].Value);
    if IsZero(GetExtended(AValue), BValue) then
      Result := P.PositiveValue
    else
      Result := P.NegativeValue;
  end
  else
    if IsZero(GetExtended(AValue)) then
      Result := P.PositiveValue
    else
      Result := P.NegativeValue;
end;

function TMethod.MultiplyMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const LValue, RValue: TValue): TValue;
begin
  Result := Operation(LValue, RValue, otMultiply);
end;

function TMethod.NewMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const PA: TParameterArray): TValue;
var
  P: TCustomParser;
  Parameter: TParameter;
  S: string;
  Value: PValue;
  BType: PType;
begin
  Check(AFunction, PA, NewParameterMinCount, NewParameterMaxCount);
  Check(FParser, AFunction, 1, PA[1].THandle, False);
  P := TCustomParser(FParser);
  Parameter := GetParameter(P, Header, PA[0]);
  Check(FParser, AFunction, 0, Parameter.THandle, True);
  S := Trim(Parameter.Text);
  if Assigned(P.FindFunction(S)) then Result := P.NegativeValue
  else begin
    Parameter := GetParameter(P, Header, PA[1]);
    P.BeginUpdate;
    try
      New(Value);
      try
        Value^ := Parameter.Value;
        if P.GetType(Parameter.THandle, BType) then
          Value^ := Convert(Value^, BType.ValueType);
        P.AddVariable(S, Value^, AsBoolean(P, Header, PA, 2, False));
        FContainer.SetVariable(S, Value);
      except
        Dispose(Value);
        raise;
      end;
    finally
      P.EndUpdate;
    end;
    Result := P.PositiveValue;
  end;
end;

function TMethod.NotEqualMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const LValue, RValue: TValue): TValue;
var
  P: TParser;
begin
  Check(LValue.ValueType);
  Check(RValue.ValueType);
  P := TParser(FParser);
  Result := EmptyValue;
  case LValue.ValueType of
    vtByte:
      case RValue.ValueType of
        vtByte:
          if LValue.Unsigned8 <> RValue.Unsigned8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtShortint:
          if Int64(LValue.Unsigned8) <> RValue.Signed8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtWord:
          if LValue.Unsigned8 <> RValue.Unsigned16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSmallint:
          if LValue.Unsigned8 <> RValue.Signed16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtLongWord:
          if LValue.Unsigned8 <> RValue.Unsigned32 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInteger:
          if LValue.Unsigned8 <> RValue.Signed32 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeInt:
          if LValue.Unsigned8 <> RValue.NativeInt then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeUInt:
          if LValue.Unsigned8 <> RValue.NativeUInt then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInt64:
          if LValue.Unsigned8 <> RValue.Signed64 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSingle:
          if not Equal(LValue.Unsigned8, RValue.Float32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtDouble:
          if not Equal(LValue.Unsigned8, RValue.Float64) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtExtended:
          if not Equal(LValue.Unsigned8, RValue.Float80) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
      end;
    vtShortint:
      case RValue.ValueType of
        vtByte:
          if LValue.Signed8 <> Int64(RValue.Unsigned8) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtShortint:
          if LValue.Signed8 <> RValue.Signed8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtWord:
          if LValue.Signed8 <> Int64(RValue.Unsigned16) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSmallint:
          if LValue.Signed8 <> RValue.Signed16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtLongWord:
          if LValue.Signed8 <> Int64(RValue.Unsigned32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInteger:
          if LValue.Signed8 <> RValue.Signed32 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeInt:
          if LValue.Signed8 <> RValue.NativeInt then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeUInt:
          if LValue.Signed8 <> Int64(RValue.NativeUInt) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInt64:
          if LValue.Signed8 <> RValue.Signed64 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSingle:
          if not Equal(LValue.Signed8, RValue.Float32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtDouble:
          if not Equal(LValue.Signed8, RValue.Float64) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtExtended:
          if not Equal(LValue.Signed8, RValue.Float80) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
      end;
    vtWord:
      case RValue.ValueType of
        vtByte:
          if LValue.Unsigned16 <> RValue.Unsigned8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtShortint:
          if Int64(LValue.Unsigned16) <> RValue.Signed8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtWord:
          if LValue.Unsigned16 <> RValue.Unsigned16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSmallint:
          if Int64(LValue.Unsigned16) <> RValue.Signed16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtLongWord:
          if LValue.Unsigned16 <> RValue.Unsigned32 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInteger:
          if LValue.Unsigned16 <> RValue.Signed32 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeInt:
          if LValue.Unsigned16 <> RValue.NativeInt then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeUInt:
          if LValue.Unsigned16 <> RValue.NativeUInt then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInt64:
          if LValue.Unsigned16 <> RValue.Signed64 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSingle:
          if not Equal(LValue.Unsigned16, RValue.Float32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtDouble:
          if not Equal(LValue.Unsigned16, RValue.Float64) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtExtended:
          if not Equal(LValue.Unsigned16, RValue.Float80) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
      end;
    vtSmallint:
      case RValue.ValueType of
        vtByte:
          if LValue.Signed16 <> RValue.Unsigned8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtShortint:
          if LValue.Signed16 <> RValue.Signed8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtWord:
          if LValue.Signed16 <> Int64(RValue.Unsigned16) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSmallint:
          if LValue.Signed16 <> RValue.Signed16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtLongWord:
          if LValue.Signed16 <> Int64(RValue.Unsigned32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInteger:
          if LValue.Signed16 <> RValue.Signed32 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeInt:
          if LValue.Signed16 <> RValue.NativeInt then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeUInt:
          if LValue.Signed16 <> Int64(RValue.NativeUInt) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInt64:
          if LValue.Signed16 <> RValue.Signed64 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSingle:
          if not Equal(LValue.Signed16, RValue.Float32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtDouble:
          if not Equal(LValue.Signed16, RValue.Float64) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtExtended:
          if not Equal(LValue.Signed16, RValue.Float80) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
      end;
    vtLongWord:
      case RValue.ValueType of
        vtByte:
          if LValue.Unsigned32 <> RValue.Unsigned8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtShortint:
          if Int64(LValue.Unsigned32) <> RValue.Signed8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtWord:
          if LValue.Unsigned32 <> RValue.Unsigned16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSmallint:
          if Int64(LValue.Unsigned32) <> RValue.Signed16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtLongWord:
          if LValue.Unsigned32 <> RValue.Unsigned32 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInteger:
          if Int64(LValue.Unsigned32) <> RValue.Signed32 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeInt:
          if Int64(LValue.Unsigned32) <> RValue.NativeInt then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeUInt:
          if LValue.Unsigned32 <> RValue.NativeUInt then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInt64:
          if LValue.Unsigned32 <> RValue.Signed64 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSingle:
          if not Equal(LValue.Unsigned32, RValue.Float32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtDouble:
          if not Equal(LValue.Unsigned32, RValue.Float64) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtExtended:
          if not Equal(LValue.Unsigned32, RValue.Float80) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
      end;
    vtInteger:
      case RValue.ValueType of
        vtByte:
          if LValue.Signed32 <> RValue.Unsigned8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtShortint:
          if LValue.Signed32 <> RValue.Signed8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtWord:
          if LValue.Signed32 <> RValue.Unsigned16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSmallint:
          if LValue.Signed32 <> RValue.Signed16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtLongWord:
          if LValue.Signed32 <> Int64(RValue.Unsigned32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInteger:
          if LValue.Signed32 <> RValue.Signed32 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeInt:
          if LValue.Signed32 <> RValue.NativeInt then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeUInt:
          if LValue.Signed32 <> Int64(RValue.NativeUInt) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInt64:
          if LValue.Signed32 <> RValue.Signed64 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSingle:
          if not Equal(LValue.Signed32, RValue.Float32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtDouble:
          if not Equal(LValue.Signed32, RValue.Float64) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtExtended:
          if not Equal(LValue.Signed32, RValue.Float80) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
      end;
    vtNativeInt:
      case RValue.ValueType of
        vtByte:
          if LValue.NativeInt <> RValue.Unsigned8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtShortint:
          if LValue.NativeInt <> RValue.Signed8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtWord:
          if LValue.NativeInt <> RValue.Unsigned16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSmallint:
          if LValue.NativeInt <> RValue.Signed16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtLongWord:
          if LValue.NativeInt <> Int64(RValue.Unsigned32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInteger:
          if LValue.NativeInt <> RValue.Signed32 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeInt:
          if LValue.NativeInt <> RValue.NativeInt then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeUInt:
          if LValue.NativeInt <> Int64(RValue.NativeUInt) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInt64:
          if LValue.NativeInt <> RValue.Signed64 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSingle:
          if not Equal(LValue.NativeInt, RValue.Float32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtDouble:
          if not Equal(LValue.NativeInt, RValue.Float64) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtExtended:
          if not Equal(LValue.NativeInt, RValue.Float80) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
      end;
    vtNativeUInt:
      case RValue.ValueType of
        vtByte:
          if LValue.NativeUInt <> RValue.Unsigned8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtShortint:
          if Int64(LValue.NativeUInt) <> RValue.Signed8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtWord:
          if LValue.NativeUInt <> RValue.Unsigned16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSmallint:
          if Int64(LValue.NativeUInt) <> RValue.Signed16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtLongWord:
          if LValue.NativeUInt <> RValue.Unsigned32 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInteger:
          if Int64(LValue.NativeUInt) <> RValue.Signed32 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeInt:
          if Int64(LValue.NativeUInt) <> RValue.NativeInt then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeUInt:
          if LValue.NativeUInt <> RValue.NativeUInt then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInt64:
          if LValue.NativeUInt <> RValue.Signed64 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSingle:
          if not Equal(LValue.NativeUInt, RValue.Float32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtDouble:
          if not Equal(LValue.NativeUInt, RValue.Float64) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtExtended:
          if not Equal(LValue.NativeUInt, RValue.Float80) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
      end;
    vtInt64:
      case RValue.ValueType of
        vtByte:
          if LValue.Signed64 <> RValue.Unsigned8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtShortint:
          if LValue.Signed64 <> RValue.Signed8 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtWord:
          if LValue.Signed64 <> RValue.Unsigned16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSmallint:
          if LValue.Signed64 <> RValue.Signed16 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtLongWord:
          if LValue.Signed64 <> RValue.Unsigned32 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInteger:
          if LValue.Signed64 <> RValue.Signed32 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeInt:
          if LValue.Signed64 <> RValue.NativeInt then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeUInt:
          if LValue.Signed64 <> RValue.NativeUInt then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInt64:
          if LValue.Signed64 <> RValue.Signed64 then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSingle:
          if not Equal(LValue.Signed64, RValue.Float32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtDouble:
          if not Equal(LValue.Signed64, RValue.Float64) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtExtended:
          if not Equal(LValue.Signed64, RValue.Float80) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
      end;
    vtSingle:
      case RValue.ValueType of
        vtByte:
          if not Equal(LValue.Float32, RValue.Unsigned8) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtShortint:
          if not Equal(LValue.Float32, RValue.Signed8) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtWord:
          if not Equal(LValue.Float32, RValue.Unsigned16) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSmallint:
          if not Equal(LValue.Float32, RValue.Signed16) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtLongWord:
          if not Equal(LValue.Float32, RValue.Unsigned32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInteger:
          if not Equal(LValue.Float32, RValue.Signed32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeInt:
          if not Equal(LValue.Float32, RValue.NativeInt) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeUInt:
          if not Equal(LValue.Float32, RValue.NativeUInt) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInt64:
          if not Equal(LValue.Float32, RValue.Signed64) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSingle:
          if not Equal(LValue.Float32, RValue.Float32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtDouble:
          if not Equal(LValue.Float32, RValue.Float64) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtExtended:
          if not Equal(LValue.Float32, RValue.Float80) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
      end;
    vtDouble:
      case RValue.ValueType of
        vtByte:
          if not Equal(LValue.Float64, RValue.Unsigned8) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtShortint:
          if not Equal(LValue.Float64, RValue.Signed8) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtWord:
          if not Equal(LValue.Float64, RValue.Unsigned16) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSmallint:
          if not Equal(LValue.Float64, RValue.Signed16) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtLongWord:
          if not Equal(LValue.Float64, RValue.Unsigned32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInteger:
          if not Equal(LValue.Float64, RValue.Signed32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeInt:
          if not Equal(LValue.Float64, RValue.NativeInt) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeUInt:
          if not Equal(LValue.Float64, RValue.NativeUInt) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInt64:
          if not Equal(LValue.Float64, RValue.Signed64) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSingle:
          if not Equal(LValue.Float64, RValue.Float32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtDouble:
          if not Equal(LValue.Float64, RValue.Float64) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtExtended:
          if not Equal(LValue.Float64, RValue.Float80) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
      end;
    vtExtended:
      case RValue.ValueType of
        vtByte:
          if not Equal(LValue.Float80, RValue.Unsigned8) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtShortint:
          if not Equal(LValue.Float80, RValue.Signed8) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtWord:
          if not Equal(LValue.Float80, RValue.Unsigned16) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSmallint:
          if not Equal(LValue.Float80, RValue.Signed16) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtLongWord:
          if not Equal(LValue.Float80, RValue.Unsigned32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInteger:
          if not Equal(LValue.Float80, RValue.Signed32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeInt:
          if not Equal(LValue.Float80, RValue.NativeInt) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtNativeUInt:
          if not Equal(LValue.Float80, RValue.NativeUInt) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtInt64:
          if not Equal(LValue.Float80, RValue.Signed64) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtSingle:
          if not Equal(LValue.Float80, RValue.Float32) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtDouble:
          if not Equal(LValue.Float80, RValue.Float64) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
        vtExtended:
          if not Equal(LValue.Float80, RValue.Float80) then
            Result := P.PositiveValue
          else
            Result := P.NegativeValue;
      end;
  end;
  Result.ValueType := vtInteger;
end;

function TMethod.NotMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const Value: TValue): TValue;
begin
  Check(Value.ValueType);
  Result := EmptyValue;
  case Value.ValueType of
    vtByte: AssignSmallint(Result, not Value.Unsigned8);
    vtShortint: AssignSmallint(Result, not Value.Signed8);
    vtWord: AssignInteger(Result, not Value.Unsigned16);
    vtSmallint: AssignInteger(Result, not Value.Signed16);
    vtLongWord: AssignInt64(Result, not Value.Unsigned32);
    vtInteger: AssignInt64(Result, not Value.Signed32);
    vtNativeInt: AssignInt64(Result, not Value.NativeInt);
    vtNativeUInt: AssignInt64(Result, not Value.NativeUInt);
    vtInt64: AssignInt64(Result, not Value.Signed64);
    vtSingle: AssignInt64(Result, not Round(Value.Float32));
    vtDouble: AssignInt64(Result, not Round(Value.Float64));
    vtExtended: AssignInt64(Result, not Round(Value.Float80));
  end;
end;

function TMethod.OrMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const LValue, RValue: TValue): TValue;
begin
  Check(LValue.ValueType);
  Check(RValue.ValueType);
  Result := EmptyValue;
  case LValue.ValueType of
    vtByte:
      case RValue.ValueType of
        vtByte: AssignInteger(Result, LValue.Unsigned8 or RValue.Unsigned8);
        vtShortint: AssignInteger(Result, Int64(LValue.Unsigned8) or Int64(RValue.Signed8));
        vtWord: AssignInteger(Result, LValue.Unsigned8 or RValue.Unsigned16);
        vtSmallint: AssignInteger(Result, LValue.Unsigned8 or RValue.Signed16);
        vtLongWord: AssignInt64(Result, Int64(LValue.Unsigned8) or Int64(RValue.Unsigned32));
        vtInteger: AssignInt64(Result, Int64(LValue.Unsigned8) or Int64(RValue.Signed32));
        vtNativeInt: AssignInt64(Result, Int64(LValue.Unsigned8) or Int64(RValue.NativeInt));
        vtNativeUInt: AssignInt64(Result, Int64(LValue.Unsigned8) or Int64(RValue.NativeUInt));
        vtInt64: AssignInt64(Result, Int64(LValue.Unsigned8) or RValue.Signed64);
        vtSingle: AssignSingle(Result, LValue.Unsigned8 or Round(RValue.Float32));
        vtDouble: AssignDouble(Result, LValue.Unsigned8 or Round(RValue.Float64));
        vtExtended: AssignExtended(Result, LValue.Unsigned8 or Round(RValue.Float80));
      end;
    vtShortint:
      case RValue.ValueType of
        vtByte: AssignInteger(Result, Int64(LValue.Signed8) or Int64(RValue.Unsigned8));
        vtShortint: AssignInteger(Result, LValue.Signed8 or RValue.Signed8);
        vtWord: AssignInteger(Result, Int64(LValue.Signed8) or Int64(RValue.Unsigned16));
        vtSmallint: AssignInteger(Result, LValue.Signed8 or RValue.Signed16);
        vtLongWord: AssignInt64(Result, Int64(LValue.Signed8) or Int64(RValue.Unsigned32));
        vtInteger: AssignInt64(Result, Int64(LValue.Signed8) or Int64(RValue.Signed32));
        vtNativeInt: AssignInt64(Result, Int64(LValue.Signed8) or Int64(RValue.NativeInt));
        vtNativeUInt: AssignInt64(Result, Int64(LValue.Signed8) or Int64(RValue.NativeUInt));
        vtInt64: AssignInt64(Result, Int64(LValue.Signed8) or RValue.Signed64);
        vtSingle: AssignSingle(Result, LValue.Signed8 or Round(RValue.Float32));
        vtDouble: AssignDouble(Result, LValue.Signed8 or Round(RValue.Float64));
        vtExtended: AssignExtended(Result, LValue.Signed8 or Round(RValue.Float80));
      end;
    vtWord:
      case RValue.ValueType of
        vtByte: AssignInteger(Result, LValue.Unsigned16 or RValue.Unsigned8);
        vtShortint: AssignInteger(Result, Int64(LValue.Unsigned16) or Int64(RValue.Signed8));
        vtWord: AssignInteger(Result, LValue.Unsigned16 or RValue.Unsigned16);
        vtSmallint: AssignInteger(Result, Int64(LValue.Unsigned16) or Int64(RValue.Signed16));
        vtLongWord: AssignInt64(Result, Int64(LValue.Unsigned16) or Int64(RValue.Unsigned32));
        vtInteger: AssignInt64(Result, Int64(LValue.Unsigned16) or Int64(RValue.Signed32));
        vtNativeInt: AssignInt64(Result, Int64(LValue.Unsigned16) or Int64(RValue.NativeInt));
        vtNativeUInt: AssignInt64(Result, Int64(LValue.Unsigned16) or Int64(RValue.NativeUInt));
        vtInt64: AssignInt64(Result, Int64(LValue.Unsigned16) or RValue.Signed64);
        vtSingle: AssignSingle(Result, LValue.Unsigned16 or Round(RValue.Float32));
        vtDouble: AssignDouble(Result, LValue.Unsigned16 or Round(RValue.Float64));
        vtExtended: AssignExtended(Result, LValue.Unsigned16 or Round(RValue.Float80));
      end;
    vtSmallint:
      case RValue.ValueType of
        vtByte: AssignInteger(Result, LValue.Signed16 or RValue.Unsigned8);
        vtShortint: AssignInteger(Result, LValue.Signed16 or RValue.Signed8);
        vtWord: AssignInteger(Result, Int64(LValue.Signed16) or Int64(RValue.Unsigned16));
        vtSmallint: AssignInteger(Result, LValue.Signed16 or RValue.Signed16);
        vtLongWord: AssignInt64(Result, Int64(LValue.Signed16) or Int64(RValue.Unsigned32));
        vtInteger: AssignInt64(Result, Int64(LValue.Signed16) or Int64(RValue.Signed32));
        vtNativeInt: AssignInt64(Result, Int64(LValue.Signed16) or Int64(RValue.NativeInt));
        vtNativeUInt: AssignInt64(Result, Int64(LValue.Signed16) or Int64(RValue.NativeUInt));
        vtInt64: AssignInt64(Result, Int64(LValue.Signed16) or RValue.Signed64);
        vtSingle: AssignSingle(Result, LValue.Signed16 or Round(RValue.Float32));
        vtDouble: AssignDouble(Result, LValue.Signed16 or Round(RValue.Float64));
        vtExtended: AssignExtended(Result, LValue.Signed16 or Round(RValue.Float80));
      end;
    vtLongWord:
      case RValue.ValueType of
        vtByte: AssignInt64(Result, Int64(LValue.Unsigned32) or Int64(RValue.Unsigned8));
        vtShortint: AssignInt64(Result, Int64(LValue.Unsigned32) or Int64(RValue.Signed8));
        vtWord: AssignInt64(Result, Int64(LValue.Unsigned32) or Int64(RValue.Unsigned16));
        vtSmallint: AssignInt64(Result, Int64(LValue.Unsigned32) or Int64(RValue.Signed16));
        vtLongWord: AssignInt64(Result, Int64(LValue.Unsigned32) or Int64(RValue.Unsigned32));
        vtInteger: AssignInt64(Result, Int64(LValue.Unsigned32) or Int64(RValue.Signed32));
        vtNativeInt: AssignInt64(Result, Int64(LValue.Unsigned32) or Int64(RValue.NativeInt));
        vtNativeUInt: AssignInt64(Result, Int64(LValue.Unsigned32) or Int64(RValue.NativeUInt));
        vtInt64: AssignInt64(Result, Int64(LValue.Unsigned32) or RValue.Signed64);
        vtSingle: AssignSingle(Result, LValue.Unsigned32 or Round(RValue.Float32));
        vtDouble: AssignDouble(Result, LValue.Unsigned32 or Round(RValue.Float64));
        vtExtended: AssignExtended(Result, LValue.Unsigned32 or Round(RValue.Float80));
      end;
    vtInteger:
      case RValue.ValueType of
        vtByte: AssignInt64(Result, Int64(LValue.Signed32) or Int64(RValue.Unsigned8));
        vtShortint: AssignInt64(Result, Int64(LValue.Signed32) or Int64(RValue.Signed8));
        vtWord: AssignInt64(Result, Int64(LValue.Signed32) or Int64(RValue.Unsigned16));
        vtSmallint: AssignInt64(Result, Int64(LValue.Signed32) or Int64(RValue.Signed16));
        vtLongWord: AssignInt64(Result, Int64(LValue.Signed32) or Int64(RValue.Unsigned32));
        vtInteger: AssignInt64(Result, Int64(LValue.Signed32) or Int64(RValue.Signed32));
        vtNativeInt: AssignInt64(Result, Int64(LValue.Signed32) or Int64(RValue.NativeInt));
        vtNativeUInt: AssignInt64(Result, Int64(LValue.Signed32) or Int64(RValue.NativeUInt));
        vtInt64: AssignInt64(Result, Int64(LValue.Signed32) or RValue.Signed64);
        vtSingle: AssignSingle(Result, LValue.Signed32 or Round(RValue.Float32));
        vtDouble: AssignDouble(Result, LValue.Signed32 or Round(RValue.Float64));
        vtExtended: AssignExtended(Result, LValue.Signed32 or Round(RValue.Float80));
      end;
    vtNativeInt:
      case RValue.ValueType of
        vtByte: AssignInt64(Result, Int64(LValue.NativeInt) or Int64(RValue.Unsigned8));
        vtShortint: AssignInt64(Result, Int64(LValue.NativeInt) or Int64(RValue.Signed8));
        vtWord: AssignInt64(Result, Int64(LValue.NativeInt) or Int64(RValue.Unsigned16));
        vtSmallint: AssignInt64(Result, Int64(LValue.NativeInt) or Int64(RValue.Signed16));
        vtLongWord: AssignInt64(Result, Int64(LValue.NativeInt) or Int64(RValue.Unsigned32));
        vtInteger: AssignInt64(Result, Int64(LValue.NativeInt) or Int64(RValue.Signed32));
        vtNativeInt: AssignInt64(Result, Int64(LValue.NativeInt) or Int64(RValue.NativeInt));
        vtNativeUInt: AssignInt64(Result, Int64(LValue.NativeInt) or Int64(RValue.NativeUInt));
        vtInt64: AssignInt64(Result, Int64(LValue.NativeInt) or RValue.Signed64);
        vtSingle: AssignSingle(Result, LValue.NativeInt or Round(RValue.Float32));
        vtDouble: AssignDouble(Result, LValue.NativeInt or Round(RValue.Float64));
        vtExtended: AssignExtended(Result, LValue.NativeInt or Round(RValue.Float80));
      end;
    vtNativeUInt:
      case RValue.ValueType of
        vtByte: AssignInt64(Result, Int64(LValue.NativeUInt) or Int64(RValue.Unsigned8));
        vtShortint: AssignInt64(Result, Int64(LValue.NativeUInt) or Int64(RValue.Signed8));
        vtWord: AssignInt64(Result, Int64(LValue.NativeUInt) or Int64(RValue.Unsigned16));
        vtSmallint: AssignInt64(Result, Int64(LValue.NativeUInt) or Int64(RValue.Signed16));
        vtLongWord: AssignInt64(Result, Int64(LValue.NativeUInt) or Int64(RValue.Unsigned32));
        vtInteger: AssignInt64(Result, Int64(LValue.NativeUInt) or Int64(RValue.Signed32));
        vtNativeInt: AssignInt64(Result, Int64(LValue.NativeUInt) or Int64(RValue.NativeInt));
        vtNativeUInt: AssignInt64(Result, Int64(LValue.NativeUInt) or Int64(RValue.NativeUInt));
        vtInt64: AssignInt64(Result, Int64(LValue.NativeUInt) or RValue.Signed64);
        vtSingle: AssignSingle(Result, LValue.NativeUInt or Round(RValue.Float32));
        vtDouble: AssignDouble(Result, LValue.NativeUInt or Round(RValue.Float64));
        vtExtended: AssignExtended(Result, LValue.NativeUInt or Round(RValue.Float80));
      end;
    vtInt64:
      case RValue.ValueType of
        vtByte: AssignInt64(Result, Int64(LValue.Signed64) or Int64(RValue.Unsigned8));
        vtShortint: AssignInt64(Result, Int64(LValue.Signed64) or Int64(RValue.Signed8));
        vtWord: AssignInt64(Result, Int64(LValue.Signed64) or Int64(RValue.Unsigned16));
        vtSmallint: AssignInt64(Result, Int64(LValue.Signed64) or Int64(RValue.Signed16));
        vtLongWord: AssignInt64(Result, Int64(LValue.Signed64) or Int64(RValue.Unsigned32));
        vtInteger: AssignInt64(Result, Int64(LValue.Signed64) or Int64(RValue.Signed32));
        vtNativeInt: AssignInt64(Result, Int64(LValue.Signed64) or Int64(RValue.NativeInt));
        vtNativeUInt: AssignInt64(Result, Int64(LValue.Signed64) or Int64(RValue.NativeUInt));
        vtInt64: AssignInt64(Result, Int64(LValue.Signed64) or RValue.Signed64);
        vtSingle: AssignSingle(Result, LValue.Signed64 or Round(RValue.Float32));
        vtDouble: AssignDouble(Result, LValue.Signed64 or Round(RValue.Float64));
        vtExtended: AssignExtended(Result, LValue.Signed64 or Round(RValue.Float80));
      end;
    vtSingle:
      case RValue.ValueType of
        vtByte: AssignSingle(Result, Round(LValue.Float32) or RValue.Unsigned8);
        vtShortint: AssignSingle(Result, Round(LValue.Float32) or RValue.Signed8);
        vtWord: AssignSingle(Result, Round(LValue.Float32) or RValue.Unsigned16);
        vtSmallint: AssignSingle(Result, Round(LValue.Float32) or RValue.Signed16);
        vtLongWord: AssignSingle(Result, Round(LValue.Float32) or RValue.Unsigned32);
        vtInteger: AssignSingle(Result, Round(LValue.Float32) or RValue.Signed32);
        vtNativeInt: AssignSingle(Result, Round(LValue.Float32) or RValue.NativeInt);
        vtNativeUInt: AssignSingle(Result, Round(LValue.Float32) or RValue.NativeUInt);
        vtInt64: AssignSingle(Result, Round(LValue.Float32) or RValue.Signed64);
        vtSingle: AssignSingle(Result, Round(LValue.Float32) or Round(RValue.Float32));
        vtDouble: AssignDouble(Result, Round(LValue.Float32) or Round(RValue.Float64));
        vtExtended: AssignExtended(Result, Round(LValue.Float32) or Round(RValue.Float80));
      end;
    vtDouble:
      case RValue.ValueType of
        vtByte: AssignDouble(Result, Round(LValue.Float64) or RValue.Unsigned8);
        vtShortint: AssignDouble(Result, Round(LValue.Float64) or RValue.Signed8);
        vtWord: AssignDouble(Result, Round(LValue.Float64) or RValue.Unsigned16);
        vtSmallint: AssignDouble(Result, Round(LValue.Float64) or RValue.Signed16);
        vtLongWord: AssignDouble(Result, Round(LValue.Float64) or RValue.Unsigned32);
        vtInteger: AssignDouble(Result, Round(LValue.Float64) or RValue.Signed32);
        vtNativeInt: AssignDouble(Result, Round(LValue.Float64) or RValue.NativeInt);
        vtNativeUInt: AssignDouble(Result, Round(LValue.Float64) or RValue.NativeUInt);
        vtInt64: AssignDouble(Result, Round(LValue.Float64) or RValue.Signed64);
        vtSingle: AssignDouble(Result, Round(LValue.Float64) or Round(RValue.Float32));
        vtDouble: AssignDouble(Result, Round(LValue.Float64) or Round(RValue.Float64));
        vtExtended: AssignExtended(Result, Round(LValue.Float64) or Round(RValue.Float80));
      end;
    vtExtended:
      case RValue.ValueType of
        vtByte: AssignExtended(Result, Round(LValue.Float80) or RValue.Unsigned8);
        vtShortint: AssignExtended(Result, Round(LValue.Float80) or RValue.Signed8);
        vtWord: AssignExtended(Result, Round(LValue.Float80) or RValue.Unsigned16);
        vtSmallint: AssignExtended(Result, Round(LValue.Float80) or RValue.Signed16);
        vtLongWord: AssignExtended(Result, Round(LValue.Float80) or RValue.Unsigned32);
        vtInteger: AssignExtended(Result, Round(LValue.Float80) or RValue.Signed32);
        vtNativeInt: AssignExtended(Result, Round(LValue.Float80) or RValue.NativeInt);
        vtNativeUInt: AssignExtended(Result, Round(LValue.Float80) or RValue.NativeUInt);
        vtInt64: AssignExtended(Result, Round(LValue.Float80) or RValue.Signed64);
        vtSingle: AssignExtended(Result, Round(LValue.Float80) or Round(RValue.Float32));
        vtDouble: AssignExtended(Result, Round(LValue.Float80) or Round(RValue.Float64));
        vtExtended: AssignExtended(Result, Round(LValue.Float80) or Round(RValue.Float80));
      end;
  end;
end;

function TMethod.ParseMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const PA: TParameterArray): TValue;
var
  P: TParser;
  Script: TScript;
begin
  Enter(MethodSync);
  try
    Check(AFunction, PA, ParseParameterCount);
    if Length(PA) > 1 then
      Check(FParser, AFunction, 1, PA[1].THandle, False);
    P := TParser(FParser);
    Script := nil;
    try
      P.StringToScript(DequoteDouble(PA[0].Text, P.FData.FA[P.DerivHandle].Name, P.Bracket), Script);
      PScriptHeader(Script).RedirectCategory := Header.RedirectCategory;
      Result := P.ExecuteScript(Script)^;
    finally
      Script := nil;
    end;
  finally
    Leave(MethodSync);
  end;
end;

function TMethod.PredMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const Value: TValue): TValue;
begin
  Check(Value.ValueType);
  case Value.ValueType of
    vtByte: AssignSmallint(Result, Pred(Value.Unsigned8));
    vtShortint: AssignSmallint(Result, Pred(Value.Signed8));
    vtWord: AssignInteger(Result, Pred(Value.Unsigned16));
    vtSmallint: AssignInteger(Result, Pred(Value.Signed16));
    vtLongWord: AssignInt64(Result, Pred(Value.Unsigned32));
    vtInteger: AssignInt64(Result, Pred(Value.Signed32));
    vtNativeInt: AssignInt64(Result, Pred(Value.NativeInt));
    vtNativeUInt: AssignInt64(Result, Pred(Value.NativeUInt));
    vtInt64: AssignInt64(Result, Pred(Value.Signed64));
    vtSingle: AssignInt64(Result, Pred(Round(Value.Float32)));
    vtDouble: AssignInt64(Result, Pred(Round(Value.Float64)));
    vtExtended: AssignInt64(Result, Pred(Round(Value.Float80)));
  end;
end;

function TMethod.RepeatMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const PA: TParameterArray): TValue;
var
  P: TCustomParser;
begin
  Check(AFunction, PA, AFunction.Method.Parameter.Count);
  Check(FParser, AFunction, PA, False);
  Result := EmptyValue;
  P := TCustomParser(FParser);
  repeat
    AssignBoolean(Result, AsBoolean(P, Header, PA[0]) or GetBoolean(Result));
  until AsBoolean(P, Header, PA[1]);
end;

function TMethod.SameValueMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const PA: TParameterArray): TValue;
var
  P: TParser;
  AValue, BValue: TValue;
  CValue: Double;
begin
  Check(AFunction, PA, SameValueParameterMinCount, SameValueParameterMaxCount);
  Check(FParser, AFunction, PA, False);
  P := TParser(FParser);
  AValue := PA[0].Value;
  BValue := PA[1].Value;
  if Length(PA) > 2 then
  begin
    CValue := GetExtended(PA[2].Value);
    if Equal(GetExtended(AValue), GetExtended(BValue), CValue) then
      Result := P.PositiveValue
    else
      Result := P.NegativeValue;
  end
  else
    if Equal(GetExtended(AValue), GetExtended(BValue)) then
      Result := P.PositiveValue
    else
      Result := P.NegativeValue;
end;

function TMethod.ScriptMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const PA: TParameterArray): TValue;
var
  I, J: Integer;
begin
  Check(AFunction, PA, ScriptParameterMinCount, ScriptParameterMaxCount);
  Check(FParser, AFunction, PA, False);
  J := Length(PA);
  if J > 0 then
  begin
    for I := 1 to J - 1 do AsValue(TCustomParser(FParser), Header, PA[I]);
    Result := AsValue(TCustomParser(FParser), Header, PA[0]);
  end;
end;

function TMethod.SetDecimalSeparatorMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const PA: TParameterArray): TValue;
var
  P: TParser;
begin
  Check(AFunction, PA, AFunction.Method.Parameter.Count);
  Check(FParser, AFunction, 0, PA[0].THandle, True);
  P := TParser(FParser);
  if StrLen(PA[0].Text) = 1 then
  begin
    ParseFormat.DecimalSeparator := PA[0].Text[0];
    Result := P.PositiveValue;
  end
  else
    Result := P.NegativeValue;
end;

function TMethod.SetEpsilonMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const PA: TParameterArray): TValue;
var
  P: TParser;
begin
  Check(AFunction, PA, AFunction.Method.Parameter.Count);
  Check(FParser, AFunction, PA, False);
  P := TParser(FParser);
  Epsilon := GetExtended(PA[0].Value);
  Result := P.PositiveValue;
end;

function TMethod.SetMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const PA: TParameterArray): TValue;
var
  P: TCustomParser;
  Parameter: TParameter;
  S: string;
  BFunction: PFunction;
  Variable: PFunctionVariable;
begin
  Check(AFunction, PA, AFunction.Method.Parameter.Count);
  Check(FParser, AFunction, 1, PA[1].THandle, False);
  P := TCustomParser(FParser);
  Parameter := GetParameter(P, Header, PA[0]);
  Check(FParser, AFunction, 0, Parameter.THandle, True);
  S := Trim(Parameter.Text);
  BFunction := P.FindFunction(S);
  if Assigned(BFunction) and (BFunction.Method.MethodType = mtVariable) then
  begin
    Variable := @BFunction.Method.Variable;
    case Variable.VariableType of
      vtValue: Variable.Variable^ := AsValue(P, Header, PA[1]);
      vtValueRef: AssignValue(Variable.VariableRef, AsValue(P, Header, PA[1]));
    end;
    Result := P.PositiveValue;
  end
  else
    Result := P.NegativeValue;
end;

function TMethod.ShlMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const LValue, RValue: TValue): TValue;
begin
  Check(LValue.ValueType);
  Check(RValue.ValueType);
  Result := EmptyValue;
  case LValue.ValueType of
    vtByte:
      case RValue.ValueType of
        vtByte: AssignInteger(Result, LValue.Unsigned8 shl RValue.Unsigned8);
        vtShortint: AssignInteger(Result, LValue.Unsigned8 shl RValue.Signed8);
        vtWord: AssignInteger(Result, LValue.Unsigned8 shl RValue.Unsigned16);
        vtSmallint: AssignInteger(Result, LValue.Unsigned8 shl RValue.Signed16);
        vtLongWord: AssignInt64(Result, Int64(LValue.Unsigned8) shl Int64(RValue.Unsigned32));
        vtInteger: AssignInt64(Result, Int64(LValue.Unsigned8) shl Int64(RValue.Signed32));
        vtNativeInt: AssignInt64(Result, Int64(LValue.Unsigned8) shl Int64(RValue.NativeInt));
        vtNativeUInt: AssignInt64(Result, Int64(LValue.Unsigned8) shl Int64(RValue.NativeUInt));
        vtInt64: AssignInt64(Result, Int64(LValue.Unsigned8) shl RValue.Signed64);
        vtSingle: AssignSingle(Result, LValue.Unsigned8 shl Round(RValue.Float32));
        vtDouble: AssignDouble(Result, LValue.Unsigned8 shl Round(RValue.Float64));
        vtExtended: AssignExtended(Result, LValue.Unsigned8 shl Round(RValue.Float80));
      end;
    vtShortint:
      case RValue.ValueType of
        vtByte: AssignInteger(Result, LValue.Signed8 shl RValue.Unsigned8);
        vtShortint: AssignInteger(Result, LValue.Signed8 shl RValue.Signed8);
        vtWord: AssignInteger(Result, LValue.Signed8 shl RValue.Unsigned16);
        vtSmallint: AssignInteger(Result, LValue.Signed8 shl RValue.Signed16);
        vtLongWord: AssignInt64(Result, Int64(LValue.Signed8) shl Int64(RValue.Unsigned32));
        vtInteger: AssignInt64(Result, Int64(LValue.Signed8) shl Int64(RValue.Signed32));
        vtNativeInt: AssignInt64(Result, Int64(LValue.Signed8) shl Int64(RValue.NativeInt));
        vtNativeUInt: AssignInt64(Result, Int64(LValue.Signed8) shl Int64(RValue.NativeUInt));
        vtInt64: AssignInt64(Result, Int64(LValue.Signed8) shl RValue.Signed64);
        vtSingle: AssignSingle(Result, LValue.Signed8 shl Round(RValue.Float32));
        vtDouble: AssignDouble(Result, LValue.Signed8 shl Round(RValue.Float64));
        vtExtended: AssignExtended(Result, LValue.Signed8 shl Round(RValue.Float80));
      end;
    vtWord:
      case RValue.ValueType of
        vtByte: AssignInteger(Result, LValue.Unsigned16 shl RValue.Unsigned8);
        vtShortint: AssignInteger(Result, LValue.Unsigned16 shl RValue.Signed8);
        vtWord: AssignInteger(Result, LValue.Unsigned16 shl RValue.Unsigned16);
        vtSmallint: AssignInteger(Result, LValue.Unsigned16 shl RValue.Signed16);
        vtLongWord: AssignInt64(Result, Int64(LValue.Unsigned16) shl Int64(RValue.Unsigned32));
        vtInteger: AssignInt64(Result, Int64(LValue.Unsigned16) shl Int64(RValue.Signed32));
        vtNativeInt: AssignInt64(Result, Int64(LValue.Unsigned16) shl Int64(RValue.NativeInt));
        vtNativeUInt: AssignInt64(Result, Int64(LValue.Unsigned16) shl Int64(RValue.NativeUInt));
        vtInt64: AssignInt64(Result, Int64(LValue.Unsigned16) shl RValue.Signed64);
        vtSingle: AssignSingle(Result, LValue.Unsigned16 shl Round(RValue.Float32));
        vtDouble: AssignDouble(Result, LValue.Unsigned16 shl Round(RValue.Float64));
        vtExtended: AssignExtended(Result, LValue.Unsigned16 shl Round(RValue.Float80));
      end;
    vtSmallint:
      case RValue.ValueType of
        vtByte: AssignInteger(Result, LValue.Signed16 shl RValue.Unsigned8);
        vtShortint: AssignInteger(Result, LValue.Signed16 shl RValue.Signed8);
        vtWord: AssignInteger(Result, LValue.Signed16 shl RValue.Unsigned16);
        vtSmallint: AssignInteger(Result, LValue.Signed16 shl RValue.Signed16);
        vtLongWord: AssignInt64(Result, Int64(LValue.Signed16) shl Int64(RValue.Unsigned32));
        vtInteger: AssignInt64(Result, Int64(LValue.Signed16) shl Int64(RValue.Signed32));
        vtNativeInt: AssignInt64(Result, Int64(LValue.Signed16) shl Int64(RValue.NativeInt));
        vtNativeUInt: AssignInt64(Result, Int64(LValue.Signed16) shl Int64(RValue.NativeUInt));
        vtInt64: AssignInt64(Result, Int64(LValue.Signed16) shl RValue.Signed64);
        vtSingle: AssignSingle(Result, LValue.Signed16 shl Round(RValue.Float32));
        vtDouble: AssignDouble(Result, LValue.Signed16 shl Round(RValue.Float64));
        vtExtended: AssignExtended(Result, LValue.Signed16 shl Round(RValue.Float80));
      end;
    vtLongWord:
      case RValue.ValueType of
        vtByte: AssignInt64(Result, Int64(LValue.Unsigned32) shl Int64(RValue.Unsigned8));
        vtShortint: AssignInt64(Result, Int64(LValue.Unsigned32) shl Int64(RValue.Signed8));
        vtWord: AssignInt64(Result, Int64(LValue.Unsigned32) shl Int64(RValue.Unsigned16));
        vtSmallint: AssignInt64(Result, Int64(LValue.Unsigned32) shl Int64(RValue.Signed16));
        vtLongWord: AssignInt64(Result, Int64(LValue.Unsigned32) shl Int64(RValue.Unsigned32));
        vtInteger: AssignInt64(Result, Int64(LValue.Unsigned32) shl Int64(RValue.Signed32));
        vtNativeInt: AssignInt64(Result, Int64(LValue.Unsigned32) shl Int64(RValue.NativeInt));
        vtNativeUInt: AssignInt64(Result, Int64(LValue.Unsigned32) shl Int64(RValue.NativeUInt));
        vtInt64: AssignInt64(Result, Int64(LValue.Unsigned32) shl RValue.Signed64);
        vtSingle: AssignSingle(Result, LValue.Unsigned32 shl Round(RValue.Float32));
        vtDouble: AssignDouble(Result, LValue.Unsigned32 shl Round(RValue.Float64));
        vtExtended: AssignExtended(Result, LValue.Unsigned32 shl Round(RValue.Float80));
      end;
    vtInteger:
      case RValue.ValueType of
        vtByte: AssignInt64(Result, Int64(LValue.Signed32) shl Int64(RValue.Unsigned8));
        vtShortint: AssignInt64(Result, Int64(LValue.Signed32) shl Int64(RValue.Signed8));
        vtWord: AssignInt64(Result, Int64(LValue.Signed32) shl Int64(RValue.Unsigned16));
        vtSmallint: AssignInt64(Result, Int64(LValue.Signed32) shl Int64(RValue.Signed16));
        vtLongWord: AssignInt64(Result, Int64(LValue.Signed32) shl Int64(RValue.Unsigned32));
        vtInteger: AssignInt64(Result, Int64(LValue.Signed32) shl Int64(RValue.Signed32));
        vtNativeInt: AssignInt64(Result, Int64(LValue.Signed32) shl Int64(RValue.NativeInt));
        vtNativeUInt: AssignInt64(Result, Int64(LValue.Signed32) shl Int64(RValue.NativeUInt));
        vtInt64: AssignInt64(Result, Int64(LValue.Signed32) shl RValue.Signed64);
        vtSingle: AssignSingle(Result, LValue.Signed32 shl Round(RValue.Float32));
        vtDouble: AssignDouble(Result, LValue.Signed32 shl Round(RValue.Float64));
        vtExtended: AssignExtended(Result, LValue.Signed32 shl Round(RValue.Float80));
      end;
    vtNativeInt:
      case RValue.ValueType of
        vtByte: AssignInt64(Result, Int64(LValue.NativeInt) shl Int64(RValue.Unsigned8));
        vtShortint: AssignInt64(Result, Int64(LValue.NativeInt) shl Int64(RValue.Signed8));
        vtWord: AssignInt64(Result, Int64(LValue.NativeInt) shl Int64(RValue.Unsigned16));
        vtSmallint: AssignInt64(Result, Int64(LValue.NativeInt) shl Int64(RValue.Signed16));
        vtLongWord: AssignInt64(Result, Int64(LValue.NativeInt) shl Int64(RValue.Unsigned32));
        vtInteger: AssignInt64(Result, Int64(LValue.NativeInt) shl Int64(RValue.Signed32));
        vtNativeInt: AssignInt64(Result, Int64(LValue.NativeInt) shl Int64(RValue.NativeInt));
        vtNativeUInt: AssignInt64(Result, Int64(LValue.NativeInt) shl Int64(RValue.NativeUInt));
        vtInt64: AssignInt64(Result, Int64(LValue.NativeInt) shl RValue.Signed64);
        vtSingle: AssignSingle(Result, LValue.NativeInt shl Round(RValue.Float32));
        vtDouble: AssignDouble(Result, LValue.NativeInt shl Round(RValue.Float64));
        vtExtended: AssignExtended(Result, LValue.NativeInt shl Round(RValue.Float80));
      end;
    vtNativeUInt:
      case RValue.ValueType of
        vtByte: AssignInt64(Result, Int64(LValue.NativeUInt) shl Int64(RValue.Unsigned8));
        vtShortint: AssignInt64(Result, Int64(LValue.NativeUInt) shl Int64(RValue.Signed8));
        vtWord: AssignInt64(Result, Int64(LValue.NativeUInt) shl Int64(RValue.Unsigned16));
        vtSmallint: AssignInt64(Result, Int64(LValue.NativeUInt) shl Int64(RValue.Signed16));
        vtLongWord: AssignInt64(Result, Int64(LValue.NativeUInt) shl Int64(RValue.Unsigned32));
        vtInteger: AssignInt64(Result, Int64(LValue.NativeUInt) shl Int64(RValue.Signed32));
        vtNativeInt: AssignInt64(Result, Int64(LValue.NativeUInt) shl Int64(RValue.NativeInt));
        vtNativeUInt: AssignInt64(Result, Int64(LValue.NativeUInt) shl Int64(RValue.NativeUInt));
        vtInt64: AssignInt64(Result, Int64(LValue.NativeUInt) shl RValue.Signed64);
        vtSingle: AssignSingle(Result, LValue.NativeUInt shl Round(RValue.Float32));
        vtDouble: AssignDouble(Result, LValue.NativeUInt shl Round(RValue.Float64));
        vtExtended: AssignExtended(Result, LValue.NativeUInt shl Round(RValue.Float80));
      end;
    vtInt64:
      case RValue.ValueType of
        vtByte: AssignInt64(Result, Int64(LValue.Signed64) shl Int64(RValue.Unsigned8));
        vtShortint: AssignInt64(Result, Int64(LValue.Signed64) shl Int64(RValue.Signed8));
        vtWord: AssignInt64(Result, Int64(LValue.Signed64) shl Int64(RValue.Unsigned16));
        vtSmallint: AssignInt64(Result, Int64(LValue.Signed64) shl Int64(RValue.Signed16));
        vtLongWord: AssignInt64(Result, Int64(LValue.Signed64) shl Int64(RValue.Unsigned32));
        vtInteger: AssignInt64(Result, Int64(LValue.Signed64) shl Int64(RValue.Signed32));
        vtNativeInt: AssignInt64(Result, Int64(LValue.Signed64) shl Int64(RValue.NativeInt));
        vtNativeUInt: AssignInt64(Result, Int64(LValue.Signed64) shl Int64(RValue.NativeUInt));
        vtInt64: AssignInt64(Result, Int64(LValue.Signed64) shl RValue.Signed64);
        vtSingle: AssignSingle(Result, LValue.Signed64 shl Round(RValue.Float32));
        vtDouble: AssignDouble(Result, LValue.Signed64 shl Round(RValue.Float64));
        vtExtended: AssignExtended(Result, LValue.Signed64 shl Round(RValue.Float80));
      end;
    vtSingle:
      case RValue.ValueType of
        vtByte: AssignSingle(Result, Round(LValue.Float32) shl RValue.Unsigned8);
        vtShortint: AssignSingle(Result, Round(LValue.Float32) shl RValue.Signed8);
        vtWord: AssignSingle(Result, Round(LValue.Float32) shl RValue.Unsigned16);
        vtSmallint: AssignSingle(Result, Round(LValue.Float32) shl RValue.Signed16);
        vtLongWord: AssignSingle(Result, Round(LValue.Float32) shl RValue.Unsigned32);
        vtInteger: AssignSingle(Result, Round(LValue.Float32) shl RValue.Signed32);
        vtNativeInt: AssignSingle(Result, Round(LValue.Float32) shl RValue.NativeInt);
        vtNativeUInt: AssignSingle(Result, Round(LValue.Float32) shl RValue.NativeUInt);
        vtInt64: AssignSingle(Result, Round(LValue.Float32) shl RValue.Signed64);
        vtSingle: AssignSingle(Result, Round(LValue.Float32) shl Round(RValue.Float32));
        vtDouble: AssignDouble(Result, Round(LValue.Float32) shl Round(RValue.Float64));
        vtExtended: AssignExtended(Result, Round(LValue.Float32) shl Round(RValue.Float80));
      end;
    vtDouble:
      case RValue.ValueType of
        vtByte: AssignDouble(Result, Round(LValue.Float64) shl RValue.Unsigned8);
        vtShortint: AssignDouble(Result, Round(LValue.Float64) shl RValue.Signed8);
        vtWord: AssignDouble(Result, Round(LValue.Float64) shl RValue.Unsigned16);
        vtSmallint: AssignDouble(Result, Round(LValue.Float64) shl RValue.Signed16);
        vtLongWord: AssignDouble(Result, Round(LValue.Float64) shl RValue.Unsigned32);
        vtInteger: AssignDouble(Result, Round(LValue.Float64) shl RValue.Signed32);
        vtNativeInt: AssignDouble(Result, Round(LValue.Float64) shl RValue.NativeInt);
        vtNativeUInt: AssignDouble(Result, Round(LValue.Float64) shl RValue.NativeUInt);
        vtInt64: AssignDouble(Result, Round(LValue.Float64) shl RValue.Signed64);
        vtSingle: AssignDouble(Result, Round(LValue.Float64) shl Round(RValue.Float32));
        vtDouble: AssignDouble(Result, Round(LValue.Float64) shl Round(RValue.Float64));
        vtExtended: AssignExtended(Result, Round(LValue.Float64) shl Round(RValue.Float80));
      end;
    vtExtended:
      case RValue.ValueType of
        vtByte: AssignExtended(Result, Round(LValue.Float80) shl RValue.Unsigned8);
        vtShortint: AssignExtended(Result, Round(LValue.Float80) shl RValue.Signed8);
        vtWord: AssignExtended(Result, Round(LValue.Float80) shl RValue.Unsigned16);
        vtSmallint: AssignExtended(Result, Round(LValue.Float80) shl RValue.Signed16);
        vtLongWord: AssignExtended(Result, Round(LValue.Float80) shl RValue.Unsigned32);
        vtInteger: AssignExtended(Result, Round(LValue.Float80) shl RValue.Signed32);
        vtNativeInt: AssignExtended(Result, Round(LValue.Float80) shl RValue.NativeInt);
        vtNativeUInt: AssignExtended(Result, Round(LValue.Float80) shl RValue.NativeUInt);
        vtInt64: AssignExtended(Result, Round(LValue.Float80) shl RValue.Signed64);
        vtSingle: AssignExtended(Result, Round(LValue.Float80) shl Round(RValue.Float32));
        vtDouble: AssignExtended(Result, Round(LValue.Float80) shl Round(RValue.Float64));
        vtExtended: AssignExtended(Result, Round(LValue.Float80) shl Round(RValue.Float80));
      end;
  end;
end;

function TMethod.ShrMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const LValue, RValue: TValue): TValue;
begin
  Check(LValue.ValueType);
  Check(RValue.ValueType);
  Result := EmptyValue;
  case LValue.ValueType of
    vtByte:
      case RValue.ValueType of
        vtByte: AssignInteger(Result, LValue.Unsigned8 shr RValue.Unsigned8);
        vtShortint: AssignInteger(Result, LValue.Unsigned8 shr RValue.Signed8);
        vtWord: AssignInteger(Result, LValue.Unsigned8 shr RValue.Unsigned16);
        vtSmallint: AssignInteger(Result, LValue.Unsigned8 shr RValue.Signed16);
        vtLongWord: AssignInt64(Result, Int64(LValue.Unsigned8) shr Int64(RValue.Unsigned32));
        vtInteger: AssignInt64(Result, Int64(LValue.Unsigned8) shr Int64(RValue.Signed32));
        vtNativeInt: AssignInt64(Result, Int64(LValue.Unsigned8) shr Int64(RValue.NativeInt));
        vtNativeUInt: AssignInt64(Result, Int64(LValue.Unsigned8) shr Int64(RValue.NativeUInt));
        vtInt64: AssignInt64(Result, Int64(LValue.Unsigned8) shr RValue.Signed64);
        vtSingle: AssignSingle(Result, LValue.Unsigned8 shr Round(RValue.Float32));
        vtDouble: AssignDouble(Result, LValue.Unsigned8 shr Round(RValue.Float64));
        vtExtended: AssignExtended(Result, LValue.Unsigned8 shr Round(RValue.Float80));
      end;
    vtShortint:
      case RValue.ValueType of
        vtByte: AssignInteger(Result, LValue.Signed8 shr RValue.Unsigned8);
        vtShortint: AssignInteger(Result, LValue.Signed8 shr RValue.Signed8);
        vtWord: AssignInteger(Result, LValue.Signed8 shr RValue.Unsigned16);
        vtSmallint: AssignInteger(Result, LValue.Signed8 shr RValue.Signed16);
        vtLongWord: AssignInt64(Result, Int64(LValue.Signed8) shr Int64(RValue.Unsigned32));
        vtInteger: AssignInt64(Result, Int64(LValue.Signed8) shr Int64(RValue.Signed32));
        vtNativeInt: AssignInt64(Result, Int64(LValue.Signed8) shr Int64(RValue.NativeInt));
        vtNativeUInt: AssignInt64(Result, Int64(LValue.Signed8) shr Int64(RValue.NativeUInt));
        vtInt64: AssignInt64(Result, Int64(LValue.Signed8) shr RValue.Signed64);
        vtSingle: AssignSingle(Result, LValue.Signed8 shr Round(RValue.Float32));
        vtDouble: AssignDouble(Result, LValue.Signed8 shr Round(RValue.Float64));
        vtExtended: AssignExtended(Result, LValue.Signed8 shr Round(RValue.Float80));
      end;
    vtWord:
      case RValue.ValueType of
        vtByte: AssignInteger(Result, LValue.Unsigned16 shr RValue.Unsigned8);
        vtShortint: AssignInteger(Result, LValue.Unsigned16 shr RValue.Signed8);
        vtWord: AssignInteger(Result, LValue.Unsigned16 shr RValue.Unsigned16);
        vtSmallint: AssignInteger(Result, LValue.Unsigned16 shr RValue.Signed16);
        vtLongWord: AssignInt64(Result, Int64(LValue.Unsigned16) shr Int64(RValue.Unsigned32));
        vtInteger: AssignInt64(Result, Int64(LValue.Unsigned16) shr Int64(RValue.Signed32));
        vtNativeInt: AssignInt64(Result, Int64(LValue.Unsigned16) shr Int64(RValue.NativeInt));
        vtNativeUInt: AssignInt64(Result, Int64(LValue.Unsigned16) shr Int64(RValue.NativeUInt));
        vtInt64: AssignInt64(Result, Int64(LValue.Unsigned16) shr RValue.Signed64);
        vtSingle: AssignSingle(Result, LValue.Unsigned16 shr Round(RValue.Float32));
        vtDouble: AssignDouble(Result, LValue.Unsigned16 shr Round(RValue.Float64));
        vtExtended: AssignExtended(Result, LValue.Unsigned16 shr Round(RValue.Float80));
      end;
    vtSmallint:
      case RValue.ValueType of
        vtByte: AssignInteger(Result, LValue.Signed16 shr RValue.Unsigned8);
        vtShortint: AssignInteger(Result, LValue.Signed16 shr RValue.Signed8);
        vtWord: AssignInteger(Result, LValue.Signed16 shr RValue.Unsigned16);
        vtSmallint: AssignInteger(Result, LValue.Signed16 shr RValue.Signed16);
        vtLongWord: AssignInt64(Result, Int64(LValue.Signed16) shr Int64(RValue.Unsigned32));
        vtInteger: AssignInt64(Result, Int64(LValue.Signed16) shr Int64(RValue.Signed32));
        vtNativeInt: AssignInt64(Result, Int64(LValue.Signed16) shr Int64(RValue.NativeInt));
        vtNativeUInt: AssignInt64(Result, Int64(LValue.Signed16) shr Int64(RValue.NativeUInt));
        vtInt64: AssignInt64(Result, Int64(LValue.Signed16) shr RValue.Signed64);
        vtSingle: AssignSingle(Result, LValue.Signed16 shr Round(RValue.Float32));
        vtDouble: AssignDouble(Result, LValue.Signed16 shr Round(RValue.Float64));
        vtExtended: AssignExtended(Result, LValue.Signed16 shr Round(RValue.Float80));
      end;
    vtLongWord:
      case RValue.ValueType of
        vtByte: AssignInt64(Result, Int64(LValue.Unsigned32) shr Int64(RValue.Unsigned8));
        vtShortint: AssignInt64(Result, Int64(LValue.Unsigned32) shr Int64(RValue.Signed8));
        vtWord: AssignInt64(Result, Int64(LValue.Unsigned32) shr Int64(RValue.Unsigned16));
        vtSmallint: AssignInt64(Result, Int64(LValue.Unsigned32) shr Int64(RValue.Signed16));
        vtLongWord: AssignInt64(Result, Int64(LValue.Unsigned32) shr Int64(RValue.Unsigned32));
        vtInteger: AssignInt64(Result, Int64(LValue.Unsigned32) shr Int64(RValue.Signed32));
        vtNativeInt: AssignInt64(Result, Int64(LValue.Unsigned32) shr Int64(RValue.NativeInt));
        vtNativeUInt: AssignInt64(Result, Int64(LValue.Unsigned32) shr Int64(RValue.NativeUInt));
        vtInt64: AssignInt64(Result, Int64(LValue.Unsigned32) shr RValue.Signed64);
        vtSingle: AssignSingle(Result, LValue.Unsigned32 shr Round(RValue.Float32));
        vtDouble: AssignDouble(Result, LValue.Unsigned32 shr Round(RValue.Float64));
        vtExtended: AssignExtended(Result, LValue.Unsigned32 shr Round(RValue.Float80));
      end;
    vtInteger:
      case RValue.ValueType of
        vtByte: AssignInt64(Result, Int64(LValue.Signed32) shr Int64(RValue.Unsigned8));
        vtShortint: AssignInt64(Result, Int64(LValue.Signed32) shr Int64(RValue.Signed8));
        vtWord: AssignInt64(Result, Int64(LValue.Signed32) shr Int64(RValue.Unsigned16));
        vtSmallint: AssignInt64(Result, Int64(LValue.Signed32) shr Int64(RValue.Signed16));
        vtLongWord: AssignInt64(Result, Int64(LValue.Signed32) shr Int64(RValue.Unsigned32));
        vtInteger: AssignInt64(Result, Int64(LValue.Signed32) shr Int64(RValue.Signed32));
        vtNativeInt: AssignInt64(Result, Int64(LValue.Signed32) shr Int64(RValue.NativeInt));
        vtNativeUInt: AssignInt64(Result, Int64(LValue.Signed32) shr Int64(RValue.NativeUInt));
        vtInt64: AssignInt64(Result, Int64(LValue.Signed32) shr RValue.Signed64);
        vtSingle: AssignSingle(Result, LValue.Signed32 shr Round(RValue.Float32));
        vtDouble: AssignDouble(Result, LValue.Signed32 shr Round(RValue.Float64));
        vtExtended: AssignExtended(Result, LValue.Signed32 shr Round(RValue.Float80));
      end;
    vtNativeInt:
      case RValue.ValueType of
        vtByte: AssignInt64(Result, Int64(LValue.NativeInt) shr Int64(RValue.Unsigned8));
        vtShortint: AssignInt64(Result, Int64(LValue.NativeInt) shr Int64(RValue.Signed8));
        vtWord: AssignInt64(Result, Int64(LValue.NativeInt) shr Int64(RValue.Unsigned16));
        vtSmallint: AssignInt64(Result, Int64(LValue.NativeInt) shr Int64(RValue.Signed16));
        vtLongWord: AssignInt64(Result, Int64(LValue.NativeInt) shr Int64(RValue.Unsigned32));
        vtInteger: AssignInt64(Result, Int64(LValue.NativeInt) shr Int64(RValue.Signed32));
        vtNativeInt: AssignInt64(Result, Int64(LValue.NativeInt) shr Int64(RValue.NativeInt));
        vtNativeUInt: AssignInt64(Result, Int64(LValue.NativeInt) shr Int64(RValue.NativeUInt));
        vtInt64: AssignInt64(Result, Int64(LValue.NativeInt) shr RValue.Signed64);
        vtSingle: AssignSingle(Result, LValue.NativeInt shr Round(RValue.Float32));
        vtDouble: AssignDouble(Result, LValue.NativeInt shr Round(RValue.Float64));
        vtExtended: AssignExtended(Result, LValue.NativeInt shr Round(RValue.Float80));
      end;
    vtNativeUInt:
      case RValue.ValueType of
        vtByte: AssignInt64(Result, Int64(LValue.NativeUInt) shr Int64(RValue.Unsigned8));
        vtShortint: AssignInt64(Result, Int64(LValue.NativeUInt) shr Int64(RValue.Signed8));
        vtWord: AssignInt64(Result, Int64(LValue.NativeUInt) shr Int64(RValue.Unsigned16));
        vtSmallint: AssignInt64(Result, Int64(LValue.NativeUInt) shr Int64(RValue.Signed16));
        vtLongWord: AssignInt64(Result, Int64(LValue.NativeUInt) shr Int64(RValue.Unsigned32));
        vtInteger: AssignInt64(Result, Int64(LValue.NativeUInt) shr Int64(RValue.Signed32));
        vtNativeInt: AssignInt64(Result, Int64(LValue.NativeUInt) shr Int64(RValue.NativeInt));
        vtNativeUInt: AssignInt64(Result, Int64(LValue.NativeUInt) shr Int64(RValue.NativeUInt));
        vtInt64: AssignInt64(Result, Int64(LValue.NativeUInt) shr RValue.Signed64);
        vtSingle: AssignSingle(Result, LValue.NativeUInt shr Round(RValue.Float32));
        vtDouble: AssignDouble(Result, LValue.NativeUInt shr Round(RValue.Float64));
        vtExtended: AssignExtended(Result, LValue.NativeUInt shr Round(RValue.Float80));
      end;
    vtInt64:
      case RValue.ValueType of
        vtByte: AssignInt64(Result, Int64(LValue.Signed64) shr Int64(RValue.Unsigned8));
        vtShortint: AssignInt64(Result, Int64(LValue.Signed64) shr Int64(RValue.Signed8));
        vtWord: AssignInt64(Result, Int64(LValue.Signed64) shr Int64(RValue.Unsigned16));
        vtSmallint: AssignInt64(Result, Int64(LValue.Signed64) shr Int64(RValue.Signed16));
        vtLongWord: AssignInt64(Result, Int64(LValue.Signed64) shr Int64(RValue.Unsigned32));
        vtInteger: AssignInt64(Result, Int64(LValue.Signed64) shr Int64(RValue.Signed32));
        vtNativeInt: AssignInt64(Result, Int64(LValue.Signed64) shr Int64(RValue.NativeInt));
        vtNativeUInt: AssignInt64(Result, Int64(LValue.Signed64) shr Int64(RValue.NativeUInt));
        vtInt64: AssignInt64(Result, Int64(LValue.Signed64) shr RValue.Signed64);
        vtSingle: AssignSingle(Result, LValue.Signed64 shr Round(RValue.Float32));
        vtDouble: AssignDouble(Result, LValue.Signed64 shr Round(RValue.Float64));
        vtExtended: AssignExtended(Result, LValue.Signed64 shr Round(RValue.Float80));
      end;
    vtSingle:
      case RValue.ValueType of
        vtByte: AssignSingle(Result, Round(LValue.Float32) shr RValue.Unsigned8);
        vtShortint: AssignSingle(Result, Round(LValue.Float32) shr RValue.Signed8);
        vtWord: AssignSingle(Result, Round(LValue.Float32) shr RValue.Unsigned16);
        vtSmallint: AssignSingle(Result, Round(LValue.Float32) shr RValue.Signed16);
        vtLongWord: AssignSingle(Result, Round(LValue.Float32) shr RValue.Unsigned32);
        vtInteger: AssignSingle(Result, Round(LValue.Float32) shr RValue.Signed32);
        vtNativeInt: AssignSingle(Result, Round(LValue.Float32) shr RValue.NativeInt);
        vtNativeUInt: AssignSingle(Result, Round(LValue.Float32) shr RValue.NativeUInt);
        vtInt64: AssignSingle(Result, Round(LValue.Float32) shr RValue.Signed64);
        vtSingle: AssignSingle(Result, Round(LValue.Float32) shr Round(RValue.Float32));
        vtDouble: AssignDouble(Result, Round(LValue.Float32) shr Round(RValue.Float64));
        vtExtended: AssignExtended(Result, Round(LValue.Float32) shr Round(RValue.Float80));
      end;
    vtDouble:
      case RValue.ValueType of
        vtByte: AssignDouble(Result, Round(LValue.Float64) shr RValue.Unsigned8);
        vtShortint: AssignDouble(Result, Round(LValue.Float64) shr RValue.Signed8);
        vtWord: AssignDouble(Result, Round(LValue.Float64) shr RValue.Unsigned16);
        vtSmallint: AssignDouble(Result, Round(LValue.Float64) shr RValue.Signed16);
        vtLongWord: AssignDouble(Result, Round(LValue.Float64) shr RValue.Unsigned32);
        vtInteger: AssignDouble(Result, Round(LValue.Float64) shr RValue.Signed32);
        vtNativeInt: AssignDouble(Result, Round(LValue.Float64) shr RValue.NativeInt);
        vtNativeUInt: AssignDouble(Result, Round(LValue.Float64) shr RValue.NativeUInt);
        vtInt64: AssignDouble(Result, Round(LValue.Float64) shr RValue.Signed64);
        vtSingle: AssignDouble(Result, Round(LValue.Float64) shr Round(RValue.Float32));
        vtDouble: AssignDouble(Result, Round(LValue.Float64) shr Round(RValue.Float64));
        vtExtended: AssignExtended(Result, Round(LValue.Float64) shr Round(RValue.Float80));
      end;
    vtExtended:
      case RValue.ValueType of
        vtByte: AssignExtended(Result, Round(LValue.Float80) shr RValue.Unsigned8);
        vtShortint: AssignExtended(Result, Round(LValue.Float80) shr RValue.Signed8);
        vtWord: AssignExtended(Result, Round(LValue.Float80) shr RValue.Unsigned16);
        vtSmallint: AssignExtended(Result, Round(LValue.Float80) shr RValue.Signed16);
        vtLongWord: AssignExtended(Result, Round(LValue.Float80) shr RValue.Unsigned32);
        vtInteger: AssignExtended(Result, Round(LValue.Float80) shr RValue.Signed32);
        vtNativeInt: AssignExtended(Result, Round(LValue.Float80) shr RValue.NativeInt);
        vtNativeUInt: AssignExtended(Result, Round(LValue.Float80) shr RValue.NativeUInt);
        vtInt64: AssignExtended(Result, Round(LValue.Float80) shr RValue.Signed64);
        vtSingle: AssignExtended(Result, Round(LValue.Float80) shr Round(RValue.Float32));
        vtDouble: AssignExtended(Result, Round(LValue.Float80) shr Round(RValue.Float64));
        vtExtended: AssignExtended(Result, Round(LValue.Float80) shr Round(RValue.Float80));
      end;
  end;
end;

function TMethod.StrToFloatDefMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const PA: TParameterArray): TValue;
begin
  Check(AFunction, PA, AFunction.Method.Parameter.Count);
  Check(FParser, AFunction, 0, PA[0].THandle, True);
  Check(FParser, AFunction, 1, PA[1].THandle, False);
  AssignExtended(Result, StrToFloatDef(PA[0].Text, GetExtended(PA[1].Value), ParseFormat));
end;

function TMethod.StrToFloatMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const PA: TParameterArray): TValue;
begin
  Check(AFunction, PA, AFunction.Method.Parameter.Count);
  Check(FParser, AFunction, 0, PA[0].THandle, True);
  AssignExtended(Result, StrToFloat(PA[0].Text, ParseFormat));
end;

function TMethod.StrToIntDefMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const PA: TParameterArray): TValue;
begin
  Check(AFunction, PA, AFunction.Method.Parameter.Count);
  Check(FParser, AFunction, 0, PA[0].THandle, True);
  Check(FParser, AFunction, 1, PA[1].THandle, False);
  AssignInt64(Result, StrToInt64Def(PA[0].Text, GetInt64(PA[1].Value)));
end;

function TMethod.StrToIntMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const PA: TParameterArray): TValue;
begin
  Check(AFunction, PA, AFunction.Method.Parameter.Count);
  Check(FParser, AFunction, 0, PA[0].THandle, True);
  AssignInt64(Result, StrToInt64(PA[0].Text));
end;

function TMethod.SuccMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const Value: TValue): TValue;
begin
  Check(Value.ValueType);
  case Value.ValueType of
    vtByte: AssignSmallint(Result, Succ(Value.Unsigned8));
    vtShortint: AssignSmallint(Result, Succ(Value.Signed8));
    vtWord: AssignInteger(Result, Succ(Value.Unsigned16));
    vtSmallint: AssignInteger(Result, Succ(Value.Signed16));
    vtLongWord: AssignInt64(Result, Succ(Value.Unsigned32));
    vtInteger: AssignInt64(Result, Succ(Value.Signed32));
    vtNativeInt: AssignInt64(Result, Succ(Value.NativeInt));
    vtNativeUInt: AssignInt64(Result, Succ(Value.NativeUInt));
    vtInt64: AssignInt64(Result, Succ(Value.Signed64));
    vtSingle: AssignInt64(Result, Succ(Round(Value.Float32)));
    vtDouble: AssignInt64(Result, Succ(Round(Value.Float64)));
    vtExtended: AssignInt64(Result, Succ(Round(Value.Float80)));
  end;
end;

function TMethod.TrueMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType): TValue;
begin
  Result := TParser(FParser).PositiveValue;
end;

function TMethod.TryExceptMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const PA: TParameterArray): TValue;
var
  P: TCustomParser;
begin
  Check(AFunction, PA, AFunction.Method.Parameter.Count);
  Check(FParser, AFunction, PA, False);
  P := TCustomParser(FParser);
  try
    Result := AsValue(P, Header, PA[0]);
  except
    on EParserExit do raise;
    else
      Result := AsValue(P, Header, PA[1]);
  end;
end;

function TMethod.TryFinallyMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const PA: TParameterArray): TValue;
var
  P: TCustomParser;
begin
  Check(AFunction, PA, AFunction.Method.Parameter.Count);
  Check(FParser, AFunction, PA, False);
  P := TCustomParser(FParser);
  try
    Result := AsValue(P, Header, PA[0]);
  finally
    GetParameter(P, Header, PA[1]);
  end;
end;

function TMethod.VoidMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType): TValue;
begin
  Result := EmptyValue;
end;

function TMethod.WhileMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const PA: TParameterArray): TValue;
var
  P: TCustomParser;
begin
  Check(AFunction, PA, AFunction.Method.Parameter.Count);
  Check(FParser, AFunction, PA, False);
  Result := EmptyValue;
  P := TCustomParser(FParser);
  while AsBoolean(P, Header, PA[0]) do
    AssignBoolean(Result, AsBoolean(P, Header, PA[1]) or GetBoolean(Result))
end;

function TMethod.XorMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const LValue, RValue: TValue): TValue;
begin
  Check(LValue.ValueType);
  Check(RValue.ValueType);
  Result := EmptyValue;
  case LValue.ValueType of
    vtByte:
      case RValue.ValueType of
        vtByte: AssignInteger(Result, LValue.Unsigned8 xor RValue.Unsigned8);
        vtShortint: AssignInteger(Result, Int64(LValue.Unsigned8) xor Int64(RValue.Signed8));
        vtWord: AssignInteger(Result, LValue.Unsigned8 xor RValue.Unsigned16);
        vtSmallint: AssignInteger(Result, LValue.Unsigned8 xor RValue.Signed16);
        vtLongWord: AssignInt64(Result, Int64(LValue.Unsigned8) xor Int64(RValue.Unsigned32));
        vtInteger: AssignInt64(Result, Int64(LValue.Unsigned8) xor Int64(RValue.Signed32));
        vtNativeInt: AssignInt64(Result, Int64(LValue.Unsigned8) xor Int64(RValue.NativeInt));
        vtNativeUInt: AssignInt64(Result, Int64(LValue.Unsigned8) xor Int64(RValue.NativeUInt));
        vtInt64: AssignInt64(Result, Int64(LValue.Unsigned8) xor RValue.Signed64);
        vtSingle: AssignSingle(Result, LValue.Unsigned8 xor Round(RValue.Float32));
        vtDouble: AssignDouble(Result, LValue.Unsigned8 xor Round(RValue.Float64));
        vtExtended: AssignExtended(Result, LValue.Unsigned8 xor Round(RValue.Float80));
      end;
    vtShortint:
      case RValue.ValueType of
        vtByte: AssignInteger(Result, Int64(LValue.Signed8) xor Int64(RValue.Unsigned8));
        vtShortint: AssignInteger(Result, LValue.Signed8 xor RValue.Signed8);
        vtWord: AssignInteger(Result, Int64(LValue.Signed8) xor Int64(RValue.Unsigned16));
        vtSmallint: AssignInteger(Result, LValue.Signed8 xor RValue.Signed16);
        vtLongWord: AssignInt64(Result, Int64(LValue.Signed8) xor Int64(RValue.Unsigned32));
        vtInteger: AssignInt64(Result, Int64(LValue.Signed8) xor Int64(RValue.Signed32));
        vtNativeInt: AssignInt64(Result, Int64(LValue.Signed8) xor Int64(RValue.NativeInt));
        vtNativeUInt: AssignInt64(Result, Int64(LValue.Signed8) xor Int64(RValue.NativeUInt));
        vtInt64: AssignInt64(Result, Int64(LValue.Signed8) xor RValue.Signed64);
        vtSingle: AssignSingle(Result, LValue.Signed8 xor Round(RValue.Float32));
        vtDouble: AssignDouble(Result, LValue.Signed8 xor Round(RValue.Float64));
        vtExtended: AssignExtended(Result, LValue.Signed8 xor Round(RValue.Float80));
      end;
    vtWord:
      case RValue.ValueType of
        vtByte: AssignInteger(Result, LValue.Unsigned16 xor RValue.Unsigned8);
        vtShortint: AssignInteger(Result, Int64(LValue.Unsigned16) xor Int64(RValue.Signed8));
        vtWord: AssignInteger(Result, LValue.Unsigned16 xor RValue.Unsigned16);
        vtSmallint: AssignInteger(Result, Int64(LValue.Unsigned16) xor Int64(RValue.Signed16));
        vtLongWord: AssignInt64(Result, Int64(LValue.Unsigned16) xor Int64(RValue.Unsigned32));
        vtInteger: AssignInt64(Result, Int64(LValue.Unsigned16) xor Int64(RValue.Signed32));
        vtNativeInt: AssignInt64(Result, Int64(LValue.Unsigned16) xor Int64(RValue.NativeInt));
        vtNativeUInt: AssignInt64(Result, Int64(LValue.Unsigned16) xor Int64(RValue.NativeUInt));
        vtInt64: AssignInt64(Result, Int64(LValue.Unsigned16) xor RValue.Signed64);
        vtSingle: AssignSingle(Result, LValue.Unsigned16 xor Round(RValue.Float32));
        vtDouble: AssignDouble(Result, LValue.Unsigned16 xor Round(RValue.Float64));
        vtExtended: AssignExtended(Result, LValue.Unsigned16 xor Round(RValue.Float80));
      end;
    vtSmallint:
      case RValue.ValueType of
        vtByte: AssignInteger(Result, LValue.Signed16 xor RValue.Unsigned8);
        vtShortint: AssignInteger(Result, LValue.Signed16 xor RValue.Signed8);
        vtWord: AssignInteger(Result, Int64(LValue.Signed16) xor Int64(RValue.Unsigned16));
        vtSmallint: AssignInteger(Result, LValue.Signed16 xor RValue.Signed16);
        vtLongWord: AssignInt64(Result, Int64(LValue.Signed16) xor Int64(RValue.Unsigned32));
        vtInteger: AssignInt64(Result, Int64(LValue.Signed16) xor Int64(RValue.Signed32));
        vtNativeInt: AssignInt64(Result, Int64(LValue.Signed16) xor Int64(RValue.NativeInt));
        vtNativeUInt: AssignInt64(Result, Int64(LValue.Signed16) xor Int64(RValue.NativeUInt));
        vtInt64: AssignInt64(Result, Int64(LValue.Signed16) xor RValue.Signed64);
        vtSingle: AssignSingle(Result, LValue.Signed16 xor Round(RValue.Float32));
        vtDouble: AssignDouble(Result, LValue.Signed16 xor Round(RValue.Float64));
        vtExtended: AssignExtended(Result, LValue.Signed16 xor Round(RValue.Float80));
      end;
    vtLongWord:
      case RValue.ValueType of
        vtByte: AssignInt64(Result, Int64(LValue.Unsigned32) xor Int64(RValue.Unsigned8));
        vtShortint: AssignInt64(Result, Int64(LValue.Unsigned32) xor Int64(RValue.Signed8));
        vtWord: AssignInt64(Result, Int64(LValue.Unsigned32) xor Int64(RValue.Unsigned16));
        vtSmallint: AssignInt64(Result, Int64(LValue.Unsigned32) xor Int64(RValue.Signed16));
        vtLongWord: AssignInt64(Result, Int64(LValue.Unsigned32) xor Int64(RValue.Unsigned32));
        vtInteger: AssignInt64(Result, Int64(LValue.Unsigned32) xor Int64(RValue.Signed32));
        vtNativeInt: AssignInt64(Result, Int64(LValue.Unsigned32) xor Int64(RValue.NativeInt));
        vtNativeUInt: AssignInt64(Result, Int64(LValue.Unsigned32) xor Int64(RValue.NativeUInt));
        vtInt64: AssignInt64(Result, Int64(LValue.Unsigned32) xor RValue.Signed64);
        vtSingle: AssignSingle(Result, LValue.Unsigned32 xor Round(RValue.Float32));
        vtDouble: AssignDouble(Result, LValue.Unsigned32 xor Round(RValue.Float64));
        vtExtended: AssignExtended(Result, LValue.Unsigned32 xor Round(RValue.Float80));
      end;
    vtInteger:
      case RValue.ValueType of
        vtByte: AssignInt64(Result, Int64(LValue.Signed32) xor Int64(RValue.Unsigned8));
        vtShortint: AssignInt64(Result, Int64(LValue.Signed32) xor Int64(RValue.Signed8));
        vtWord: AssignInt64(Result, Int64(LValue.Signed32) xor Int64(RValue.Unsigned16));
        vtSmallint: AssignInt64(Result, Int64(LValue.Signed32) xor Int64(RValue.Signed16));
        vtLongWord: AssignInt64(Result, Int64(LValue.Signed32) xor Int64(RValue.Unsigned32));
        vtInteger: AssignInt64(Result, Int64(LValue.Signed32) xor Int64(RValue.Signed32));
        vtNativeInt: AssignInt64(Result, Int64(LValue.Signed32) xor Int64(RValue.NativeInt));
        vtNativeUInt: AssignInt64(Result, Int64(LValue.Signed32) xor Int64(RValue.NativeUInt));
        vtInt64: AssignInt64(Result, Int64(LValue.Signed32) xor RValue.Signed64);
        vtSingle: AssignSingle(Result, LValue.Signed32 xor Round(RValue.Float32));
        vtDouble: AssignDouble(Result, LValue.Signed32 xor Round(RValue.Float64));
        vtExtended: AssignExtended(Result, LValue.Signed32 xor Round(RValue.Float80));
      end;
    vtNativeInt:
      case RValue.ValueType of
        vtByte: AssignInt64(Result, Int64(LValue.NativeInt) xor Int64(RValue.Unsigned8));
        vtShortint: AssignInt64(Result, Int64(LValue.NativeInt) xor Int64(RValue.Signed8));
        vtWord: AssignInt64(Result, Int64(LValue.NativeInt) xor Int64(RValue.Unsigned16));
        vtSmallint: AssignInt64(Result, Int64(LValue.NativeInt) xor Int64(RValue.Signed16));
        vtLongWord: AssignInt64(Result, Int64(LValue.NativeInt) xor Int64(RValue.Unsigned32));
        vtInteger: AssignInt64(Result, Int64(LValue.NativeInt) xor Int64(RValue.Signed32));
        vtNativeInt: AssignInt64(Result, Int64(LValue.NativeInt) xor Int64(RValue.NativeInt));
        vtNativeUInt: AssignInt64(Result, Int64(LValue.NativeInt) xor Int64(RValue.NativeUInt));
        vtInt64: AssignInt64(Result, Int64(LValue.NativeInt) xor RValue.Signed64);
        vtSingle: AssignSingle(Result, LValue.NativeInt xor Round(RValue.Float32));
        vtDouble: AssignDouble(Result, LValue.NativeInt xor Round(RValue.Float64));
        vtExtended: AssignExtended(Result, LValue.NativeInt xor Round(RValue.Float80));
      end;
    vtNativeUInt:
      case RValue.ValueType of
        vtByte: AssignInt64(Result, Int64(LValue.NativeUInt) xor Int64(RValue.Unsigned8));
        vtShortint: AssignInt64(Result, Int64(LValue.NativeUInt) xor Int64(RValue.Signed8));
        vtWord: AssignInt64(Result, Int64(LValue.NativeUInt) xor Int64(RValue.Unsigned16));
        vtSmallint: AssignInt64(Result, Int64(LValue.NativeUInt) xor Int64(RValue.Signed16));
        vtLongWord: AssignInt64(Result, Int64(LValue.NativeUInt) xor Int64(RValue.Unsigned32));
        vtInteger: AssignInt64(Result, Int64(LValue.NativeUInt) xor Int64(RValue.Signed32));
        vtNativeInt: AssignInt64(Result, Int64(LValue.NativeUInt) xor Int64(RValue.NativeInt));
        vtNativeUInt: AssignInt64(Result, Int64(LValue.NativeUInt) xor Int64(RValue.NativeUInt));
        vtInt64: AssignInt64(Result, Int64(LValue.NativeUInt) xor RValue.Signed64);
        vtSingle: AssignSingle(Result, LValue.NativeUInt xor Round(RValue.Float32));
        vtDouble: AssignDouble(Result, LValue.NativeUInt xor Round(RValue.Float64));
        vtExtended: AssignExtended(Result, LValue.NativeUInt xor Round(RValue.Float80));
      end;
    vtInt64:
      case RValue.ValueType of
        vtByte: AssignInt64(Result, Int64(LValue.Signed64) xor Int64(RValue.Unsigned8));
        vtShortint: AssignInt64(Result, Int64(LValue.Signed64) xor Int64(RValue.Signed8));
        vtWord: AssignInt64(Result, Int64(LValue.Signed64) xor Int64(RValue.Unsigned16));
        vtSmallint: AssignInt64(Result, Int64(LValue.Signed64) xor Int64(RValue.Signed16));
        vtLongWord: AssignInt64(Result, Int64(LValue.Signed64) xor Int64(RValue.Unsigned32));
        vtInteger: AssignInt64(Result, Int64(LValue.Signed64) xor Int64(RValue.Signed32));
        vtNativeInt: AssignInt64(Result, Int64(LValue.Signed64) xor Int64(RValue.NativeInt));
        vtNativeUInt: AssignInt64(Result, Int64(LValue.Signed64) xor Int64(RValue.NativeUInt));
        vtInt64: AssignInt64(Result, Int64(LValue.Signed64) xor RValue.Signed64);
        vtSingle: AssignSingle(Result, LValue.Signed64 xor Round(RValue.Float32));
        vtDouble: AssignDouble(Result, LValue.Signed64 xor Round(RValue.Float64));
        vtExtended: AssignExtended(Result, LValue.Signed64 xor Round(RValue.Float80));
      end;
    vtSingle:
      case RValue.ValueType of
        vtByte: AssignSingle(Result, Round(LValue.Float32) xor RValue.Unsigned8);
        vtShortint: AssignSingle(Result, Round(LValue.Float32) xor RValue.Signed8);
        vtWord: AssignSingle(Result, Round(LValue.Float32) xor RValue.Unsigned16);
        vtSmallint: AssignSingle(Result, Round(LValue.Float32) xor RValue.Signed16);
        vtLongWord: AssignSingle(Result, Round(LValue.Float32) xor RValue.Unsigned32);
        vtInteger: AssignSingle(Result, Round(LValue.Float32) xor RValue.Signed32);
        vtNativeInt: AssignSingle(Result, Round(LValue.Float32) xor RValue.NativeInt);
        vtNativeUInt: AssignSingle(Result, Round(LValue.Float32) xor RValue.NativeUInt);
        vtInt64: AssignSingle(Result, Round(LValue.Float32) xor RValue.Signed64);
        vtSingle: AssignSingle(Result, Round(LValue.Float32) xor Round(RValue.Float32));
        vtDouble: AssignDouble(Result, Round(LValue.Float32) xor Round(RValue.Float64));
        vtExtended: AssignExtended(Result, Round(LValue.Float32) xor Round(RValue.Float80));
      end;
    vtDouble:
      case RValue.ValueType of
        vtByte: AssignDouble(Result, Round(LValue.Float64) xor RValue.Unsigned8);
        vtShortint: AssignDouble(Result, Round(LValue.Float64) xor RValue.Signed8);
        vtWord: AssignDouble(Result, Round(LValue.Float64) xor RValue.Unsigned16);
        vtSmallint: AssignDouble(Result, Round(LValue.Float64) xor RValue.Signed16);
        vtLongWord: AssignDouble(Result, Round(LValue.Float64) xor RValue.Unsigned32);
        vtInteger: AssignDouble(Result, Round(LValue.Float64) xor RValue.Signed32);
        vtNativeInt: AssignDouble(Result, Round(LValue.Float64) xor RValue.NativeInt);
        vtNativeUInt: AssignDouble(Result, Round(LValue.Float64) xor RValue.NativeUInt);
        vtInt64: AssignDouble(Result, Round(LValue.Float64) xor RValue.Signed64);
        vtSingle: AssignDouble(Result, Round(LValue.Float64) xor Round(RValue.Float32));
        vtDouble: AssignDouble(Result, Round(LValue.Float64) xor Round(RValue.Float64));
        vtExtended: AssignExtended(Result, Round(LValue.Float64) xor Round(RValue.Float80));
      end;
    vtExtended:
      case RValue.ValueType of
        vtByte: AssignExtended(Result, Round(LValue.Float80) xor RValue.Unsigned8);
        vtShortint: AssignExtended(Result, Round(LValue.Float80) xor RValue.Signed8);
        vtWord: AssignExtended(Result, Round(LValue.Float80) xor RValue.Unsigned16);
        vtSmallint: AssignExtended(Result, Round(LValue.Float80) xor RValue.Signed16);
        vtLongWord: AssignExtended(Result, Round(LValue.Float80) xor RValue.Unsigned32);
        vtInteger: AssignExtended(Result, Round(LValue.Float80) xor RValue.Signed32);
        vtNativeInt: AssignExtended(Result, Round(LValue.Float80) xor RValue.NativeInt);
        vtNativeUInt: AssignExtended(Result, Round(LValue.Float80) xor RValue.NativeUInt);
        vtInt64: AssignExtended(Result, Round(LValue.Float80) xor RValue.Signed64);
        vtSingle: AssignExtended(Result, Round(LValue.Float80) xor Round(RValue.Float32));
        vtDouble: AssignExtended(Result, Round(LValue.Float80) xor Round(RValue.Float64));
        vtExtended: AssignExtended(Result, Round(LValue.Float80) xor Round(RValue.Float80));
      end;
  end;
end;

{ TMathMethod }

function TMathMethod.AbsMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const Value: TValue): TValue;
begin
  Result := Positive(Value);
end;

function TMathMethod.ArcCosHMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const Value: TValue): TValue;
var
  AValue: Double;
begin
  AValue := GetExtended(Value);
  if (etZeroDivide in TParser(FParser).ExceptionTypeSet) and (AValue < 1) then
    AssignExtended(Result, NaN)
  else
    AssignExtended(Result, ArcCosH(AValue));
end;

function TMathMethod.ArcCosMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const Value: TValue): TValue;
var
  AValue: Double;
begin
  AValue := GetExtended(Value);
  if (etZeroDivide in TParser(FParser).ExceptionTypeSet) and ((AValue < -1) or (AValue > 1)) then
    AssignExtended(Result, NaN)
  else
    AssignExtended(Result, ArcCos(AValue));
end;

function TMathMethod.ArcCoTanHMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const Value: TValue): TValue;
begin
  {$IFDEF FPC}
  AssignExtended(Result, ArcCotH(GetExtended(Value)));
  {$ELSE}
  AssignExtended(Result, ArcCotH(GetExtended(Value)));
  {$ENDIF}
end;

function TMathMethod.ArcCoTanMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const Value: TValue): TValue;
begin
  {$IFDEF FPC}
  AssignExtended(Result, ArcCot(GetExtended(Value)));
  {$ELSE}
  AssignExtended(Result, ArcCot(GetExtended(Value)));
  {$ENDIF}
end;

function TMathMethod.ArcCscHMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const Value: TValue): TValue;
begin
  {$IFDEF FPC}
  AssignExtended(Result, ArcCscH(GetExtended(Value)));
  {$ELSE}
  AssignExtended(Result, ArcCscH(GetExtended(Value)));
  {$ENDIF}
end;

function TMathMethod.ArcCscMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const Value: TValue): TValue;
begin
  {$IFDEF FPC}
  AssignExtended(Result, ArcCsc(GetExtended(Value)));
  {$ELSE}
  AssignExtended(Result, ArcCsc(GetExtended(Value)));
  {$ENDIF}
end;

function TMathMethod.ArcSecHMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const Value: TValue): TValue;
begin
  {$IFDEF FPC}
  AssignExtended(Result, ArcSecH(GetExtended(Value)));
  {$ELSE}
  AssignExtended(Result, ArcSecH(GetExtended(Value)));
  {$ENDIF}
end;

function TMathMethod.ArcSecMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const Value: TValue): TValue;
begin
  {$IFDEF FPC}
  AssignExtended(Result, ArcSec(GetExtended(Value)));
  {$ELSE}
  AssignExtended(Result, ArcSec(GetExtended(Value)));
  {$ENDIF}
end;

function TMathMethod.ArcSinHMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const Value: TValue): TValue;
begin
  AssignExtended(Result, ArcSinH(GetExtended(Value)));
end;

function TMathMethod.ArcSinMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const Value: TValue): TValue;
var
  AValue: Double;
begin
  AValue := GetExtended(Value);
  if (etZeroDivide in TParser(FParser).ExceptionTypeSet) and ((AValue < -1) or (AValue > 1)) then
    AssignExtended(Result, NaN)
  else
    AssignExtended(Result, ArcSin(AValue));
end;

function TMathMethod.ArcTan2Method(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const PA: TParameterArray): TValue;
begin
  Check(AFunction, PA, AFunction.Method.Parameter.Count);
  Check(FParser, AFunction, PA, False);
  AssignExtended(Result, ArcTan2(GetExtended(PA[0].Value), GetExtended(PA[1].Value)));
end;

function TMathMethod.ArcTanHMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const Value: TValue): TValue;
var
  AValue: Double;
begin
  AValue := GetExtended(Value);
  if (etZeroDivide in TParser(FParser).ExceptionTypeSet) and ((AValue < -1) or (AValue > 1)) then
    AssignExtended(Result, NaN)
  else
    AssignExtended(Result, ArcTanH(AValue));
end;

function TMathMethod.ArcTanMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const Value: TValue): TValue;
begin
  AssignExtended(Result, ArcTan(GetExtended(Value)));
end;

function TMathMethod.CeilMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const Value: TValue): TValue;
begin
  AssignExtended(Result, Ceil(GetExtended(Value)));
end;

function TMathMethod.CompareDateMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const PA: TParameterArray): TValue;
begin
  Check(AFunction, PA, AFunction.Method.Parameter.Count, vrEqual);
  Check(Parser, AFunction, PA, False);
  AssignShortint(Result, CompareDate(DateOf(GetDouble(PA[0].Value)), DateOf(GetDouble(PA[1].Value))));
end;

function TMathMethod.CompareDateTimeMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const PA: TParameterArray): TValue;
begin
  Check(AFunction, PA, AFunction.Method.Parameter.Count, vrEqual);
  Check(Parser, AFunction, PA, False);
  AssignShortint(Result, CompareDateTime(GetDouble(PA[0].Value), GetDouble(PA[1].Value)));
end;

function TMathMethod.CompareTimeMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const PA: TParameterArray): TValue;
begin
  Check(AFunction, PA, AFunction.Method.Parameter.Count, vrEqual);
  Check(Parser, AFunction, PA, False);
  AssignShortint(Result, CompareTime(TimeOf(GetDouble(PA[0].Value)), TimeOf(GetDouble(PA[1].Value))));
end;

function TMathMethod.CosHMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const Value: TValue): TValue;
begin
  AssignExtended(Result, CosH(GetExtended(Value)));
end;

function TMathMethod.CosMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const Value: TValue): TValue;
begin
  AssignExtended(Result, Cos(GetExtended(Value)));
end;

function TMathMethod.CoTanHMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const Value: TValue): TValue;
begin
  {$IFDEF FPC}
  AssignExtended(Result, CotH(GetExtended(Value)));
  {$ELSE}
  AssignExtended(Result, CotH(GetExtended(Value)));
  {$ENDIF}
end;

function TMathMethod.CoTanMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const Value: TValue): TValue;
var
  AValue: Double;
begin
  AValue := GetExtended(Value);
  if (etZeroDivide in TParser(FParser).ExceptionTypeSet) and IsZero(Sin(AValue)) then
    AssignExtended(Result, NaN)
  else
    AssignExtended(Result, CoTan(AValue));
end;

function TMathMethod.CscHMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const Value: TValue): TValue;
{$IFNDEF FPC}
var
  AValue: Double;
{$ENDIF}
begin
  {$IFDEF FPC}
  AssignExtended(Result, CscH(GetExtended(Value)));
  {$ELSE}
  AValue := GetExtended(Value);
  if (etZeroDivide in TParser(FParser).ExceptionTypeSet) and IsZero(AValue) then
    AssignExtended(Result, NaN)
  else
    AssignExtended(Result, CscH(AValue));
  {$ENDIF}
end;

function TMathMethod.CscMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const Value: TValue): TValue;
var
  AValue: Double;
begin
  AValue := GetExtended(Value);
  if (etZeroDivide in TParser(FParser).ExceptionTypeSet) and IsZero(Sin(AValue)) then
    AssignExtended(Result, NaN)
  else
    AssignExtended(Result, Csc(AValue));
end;

function TMathMethod.CycleToDegMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const Value: TValue): TValue;
begin
  {$IFDEF FPC}
  AssignExtended(Result, GetExtended(Value) * 360);
  {$ELSE}
  AssignExtended(Result, CycleToDeg(GetExtended(Value)));
  {$ENDIF}
end;

function TMathMethod.CycleToGradMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const Value: TValue): TValue;
begin
  {$IFDEF FPC}
  AssignExtended(Result, GetExtended(Value) * 400);
  {$ELSE}
  AssignExtended(Result, CycleToGrad(GetExtended(Value)));
  {$ENDIF}
end;

function TMathMethod.CycleToRadMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const Value: TValue): TValue;
begin
  AssignExtended(Result, CycleToRad(GetExtended(Value)));
end;

function TMathMethod.DateMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType): TValue;
begin
  AssignDouble(Result, Date);
end;

function TMathMethod.DateOfMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const Value: TValue): TValue;
begin
  AssignDouble(Result, DateOf(GetDouble(Value)));
end;

function TMathMethod.DateTimeMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType): TValue;
begin
  AssignDouble(Result, Now);
end;

function TMathMethod.DayMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType): TValue;
var
  SystemTime: TSystemTime;
begin
  GetLocalTime(SystemTime);
  AssignWord(Result, {$IFDEF FPC}SystemTime.Day{$ELSE}SystemTime.wDay{$ENDIF});
end;

function TMathMethod.DayOfMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const Value: TValue): TValue;
begin
  AssignWord(Result, DayOf(GetDouble(Value)));
end;

function TMathMethod.DayOfTheMonthMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const Value: TValue): TValue;
begin
  AssignWord(Result, DayOfTheMonth(GetDouble(Value)));
end;

function TMathMethod.DayOfTheWeekMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const Value: TValue): TValue;
begin
  AssignWord(Result, DayOfTheWeek(GetDouble(Value)));
end;

function TMathMethod.DayOfTheYearMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const Value: TValue): TValue;
begin
  AssignWord(Result, DayOfTheYear(GetDouble(Value)));
end;

function TMathMethod.DayOfWeekMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType): TValue;
var
  SystemTime: TSystemTime;
begin
  GetLocalTime(SystemTime);
  AssignWord(Result, {$IFDEF FPC}SystemTime.DayOfWeek{$ELSE}SystemTime.wDayOfWeek{$ENDIF});
end;

function TMathMethod.DaysBetweenMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const PA: TParameterArray): TValue;
begin
  Check(AFunction, PA, AFunction.Method.Parameter.Count, vrEqual);
  Check(Parser, AFunction, PA, False);
  AssignInteger(Result, DaysBetween(GetDouble(PA[0].Value), GetDouble(PA[1].Value)));
end;

function TMathMethod.DegreeMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const LValue, RValue: TValue): TValue;
begin
  AssignExtended(Result, Power(GetExtended(LValue), GetExtended(RValue)));
end;

function TMathMethod.DegToCycleMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const Value: TValue): TValue;
begin
  {$IFDEF FPC}
  AssignExtended(Result, GetExtended(Value) / 360);
  {$ELSE}
  AssignExtended(Result, DegToCycle(GetExtended(Value)));
  {$ENDIF}
end;

function TMathMethod.DegToGradMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const Value: TValue): TValue;
begin
  AssignExtended(Result, DegToGrad(GetExtended(Value)));
end;

function TMathMethod.DegToRadMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const Value: TValue): TValue;
begin
  AssignExtended(Result, DegToRad(GetExtended(Value)));
end;

function TMathMethod.DivMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const LValue, RValue: TValue): TValue;
var
  AValue, BValue: Integer;
begin
  AValue := GetInteger(LValue);
  BValue := GetInteger(RValue);
  if (etZeroDivide in TParser(FParser).ExceptionTypeSet) and (BValue = 0) then
    AssignExtended(Result, NaN)
  else
    AssignInteger(Result, AValue div BValue);
end;

function TMathMethod.EncodeDateMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const PA: TParameterArray): TValue;
var
  Year, Month, Day: Word;
begin
  Check(AFunction, PA, AFunction.Method.Parameter.Count);
  Check(FParser, AFunction, PA, False);
  Year := GetWord(PA[0].Value);
  Month := GetWord(PA[1].Value);
  Day := GetWord(PA[2].Value);
  AssignDouble(Result, EncodeDate(Year, Month, Day));
end;

function TMathMethod.EncodeDateTimeMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const PA: TParameterArray): TValue;
var
  Year, Month, Day, Hour, Min, Sec, MSec: Word;
begin
  Check(AFunction, PA, AFunction.Method.Parameter.Count);
  Check(FParser, AFunction, PA, False);
  Year := GetWord(PA[0].Value);
  Month := GetWord(PA[1].Value);
  Day := GetWord(PA[2].Value);
  Hour := GetWord(PA[3].Value);
  Min := GetWord(PA[4].Value);
  Sec := GetWord(PA[5].Value);
  MSec := GetWord(PA[6].Value);
  AssignDouble(Result, EncodeDateTime(Year, Month, Day, Hour, Min, Sec, MSec));
end;

function TMathMethod.EncodeTimeMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const PA: TParameterArray): TValue;
var
  Hour, Min, Sec, MSec: Word;
begin
  Check(AFunction, PA, AFunction.Method.Parameter.Count);
  Check(FParser, AFunction, PA, False);
  Hour := GetWord(PA[0].Value);
  Min := GetWord(PA[1].Value);
  Sec := GetWord(PA[2].Value);
  MSec := GetWord(PA[3].Value);
  AssignDouble(Result, EncodeTime(Hour, Min, Sec, MSec));
end;

function TMathMethod.ExpMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const Value: TValue): TValue;
begin
  AssignExtended(Result, Exp(GetExtended(Value)));
end;

function TMathMethod.FactorialMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const PA: TParameterArray): TValue;
begin
  Check(AFunction, PA, AFunction.Method.Parameter.Count);
  Check(FParser, AFunction, PA, False);
  AssignInt64(Result, Factorial(GetSmallint(PA[0].Value)));
end;

function TMathMethod.FloorMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const Value: TValue): TValue;
begin
  AssignExtended(Result, Floor(GetExtended(Value)));
end;

function TMathMethod.FracMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const Value: TValue): TValue;
begin
  AssignExtended(Result, Frac(GetExtended(Value)));
end;

function TMathMethod.GetDayMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const PA: TParameterArray): TValue;
begin
  Check(AFunction, PA, AFunction.Method.Parameter.Count);
  Check(FParser, AFunction, PA, False);
  AssignWord(Result, DayOf(GetExtended(PA[0].Value)));
end;

function TMathMethod.GetDayOfWeekMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const PA: TParameterArray): TValue;
begin
  Check(AFunction, PA, AFunction.Method.Parameter.Count);
  Check(FParser, AFunction, PA, False);
  AssignWord(Result, DayOfWeek(GetExtended(PA[0].Value)));
end;

function TMathMethod.GetHourMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const PA: TParameterArray): TValue;
begin
  Check(AFunction, PA, AFunction.Method.Parameter.Count);
  Check(FParser, AFunction, PA, False);
  AssignWord(Result, HourOf(GetExtended(PA[0].Value)));
end;

function TMathMethod.GetMilliSecondMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const PA: TParameterArray): TValue;
begin
  Check(AFunction, PA, AFunction.Method.Parameter.Count);
  Check(FParser, AFunction, PA, False);
  AssignWord(Result, MilliSecondOf(GetExtended(PA[0].Value)));
end;

function TMathMethod.GetMinuteMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const PA: TParameterArray): TValue;
begin
  Check(AFunction, PA, AFunction.Method.Parameter.Count);
  Check(FParser, AFunction, PA, False);
  AssignWord(Result, MinuteOf(GetExtended(PA[0].Value)));
end;

function TMathMethod.GetMonthMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const PA: TParameterArray): TValue;
begin
  Check(AFunction, PA, AFunction.Method.Parameter.Count);
  Check(FParser, AFunction, PA, False);
  AssignWord(Result, MonthOf(GetExtended(PA[0].Value)));
end;

function TMathMethod.GetSecondMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const PA: TParameterArray): TValue;
begin
  Check(AFunction, PA, AFunction.Method.Parameter.Count);
  Check(FParser, AFunction, PA, False);
  AssignWord(Result, SecondOf(GetExtended(PA[0].Value)));
end;

function TMathMethod.GetTickCount(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType): TValue;
begin
  {$IFDEF FPC}
  AssignLongWord(Result, SysUtils.GetTickCount);
  {$ELSE}
  AssignLongWord(Result, {$IFDEF DELPHI_XE7}WinApi.Windows.GetTickCount{$ELSE}Windows.GetTickCount{$ENDIF});
  {$ENDIF}
end;

function TMathMethod.GetYearMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const PA: TParameterArray): TValue;
begin
  Check(AFunction, PA, AFunction.Method.Parameter.Count);
  Check(FParser, AFunction, PA, False);
  AssignWord(Result, YearOf(GetExtended(PA[0].Value)));
end;

function TMathMethod.GradToCycleMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const Value: TValue): TValue;
begin
  {$IFDEF FPC}
  AssignExtended(Result, GetExtended(Value) / 400);
  {$ELSE}
  AssignExtended(Result, GradToCycle(GetExtended(Value)));
  {$ENDIF}
end;

function TMathMethod.GradToDegMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const Value: TValue): TValue;
begin
  AssignExtended(Result, GradToDeg(GetExtended(Value)));
end;

function TMathMethod.GradToRadMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const Value: TValue): TValue;
begin
  AssignExtended(Result, GradToRad(GetExtended(Value)));
end;

function TMathMethod.HourMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType): TValue;
var
  SystemTime: TSystemTime;
begin
  GetLocalTime(SystemTime);
  AssignWord(Result, {$IFDEF FPC}SystemTime.Hour{$ELSE}SystemTime.wHour{$ENDIF});
end;

function TMathMethod.HourOfMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const Value: TValue): TValue;
begin
  AssignWord(Result, HourOf(GetDouble(Value)));
end;

function TMathMethod.HourOfTheDayMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const Value: TValue): TValue;
begin
  AssignWord(Result, HourOfTheDay(GetDouble(Value)));
end;

function TMathMethod.HourOfTheMonthMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const Value: TValue): TValue;
begin
  AssignWord(Result, HourOfTheMonth(GetDouble(Value)));
end;

function TMathMethod.HourOfTheWeekMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const Value: TValue): TValue;
begin
  AssignWord(Result, HourOfTheWeek(GetDouble(Value)));
end;

function TMathMethod.HourOfTheYearMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const Value: TValue): TValue;
begin
  AssignWord(Result, HourOfTheYear(GetDouble(Value)));
end;

function TMathMethod.HoursBetweenMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const PA: TParameterArray): TValue;
begin
  Check(AFunction, PA, AFunction.Method.Parameter.Count, vrEqual);
  Check(Parser, AFunction, PA, False);
  AssignInt64(Result, HoursBetween(GetDouble(PA[0].Value), GetDouble(PA[1].Value)));
end;

function TMathMethod.HypotMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const PA: TParameterArray): TValue;
begin
  Check(AFunction, PA, AFunction.Method.Parameter.Count);
  Check(FParser, AFunction, PA, False);
  AssignExtended(Result, Hypot(GetExtended(PA[0].Value), GetExtended(PA[1].Value)));
end;

function TMathMethod.IntMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const Value: TValue): TValue;
begin
  AssignExtended(Result, Int(GetExtended(Value)));
end;

function TMathMethod.IntPowerMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const PA: TParameterArray): TValue;
begin
  Check(AFunction, PA, AFunction.Method.Parameter.Count);
  Check(FParser, AFunction, PA, False);
  AssignExtended(Result, IntPower(GetExtended(PA[0].Value), GetInteger(PA[1].Value)));
end;

function TMathMethod.LdexpMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const PA: TParameterArray): TValue;
begin
  Check(AFunction, PA, AFunction.Method.Parameter.Count);
  Check(FParser, AFunction, PA, False);
  AssignExtended(Result, Ldexp(GetExtended(PA[0].Value), GetInteger(PA[1].Value)));
end;

function TMathMethod.LgMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const Value: TValue): TValue;
begin
  AssignExtended(Result, Log10(GetExtended(Value)));
end;

function TMathMethod.LnMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const Value: TValue): TValue;
begin
  AssignExtended(Result, Ln(GetExtended(Value)));
end;

function TMathMethod.LnXP1Method(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const Value: TValue): TValue;
begin
  AssignExtended(Result, LnXP1(GetExtended(Value)));
end;

function TMathMethod.Log10Method(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const Value: TValue): TValue;
begin
  AssignExtended(Result, Log10(GetExtended(Value)));
end;

function TMathMethod.Log2Method(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const Value: TValue): TValue;
begin
  AssignExtended(Result, Log2(GetExtended(Value)));
end;

function TMathMethod.LogMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const LValue, RValue: TValue): TValue;
begin
  AssignExtended(Result, LogN(GetExtended(LValue), GetExtended(RValue)));
end;

function TMathMethod.MaxIntValueMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const PA: TParameterArray): TValue;
var
  Parameter: TIntegerDynArray;
begin
  Check(AFunction, PA, AFunction.Method.Parameter.Count, vrBelow);
  Check(FParser, AFunction, PA, False);
  Parameter := IArray(PA, Low(PA), High(PA));
  try
    AssignInteger(Result, MaxIntValue(Parameter));
  finally
    Parameter := nil;
  end;
end;

function TMathMethod.MaxMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const PA: TParameterArray): TValue;
begin
  Check(AFunction, PA, AFunction.Method.Parameter.Count);
  Check(FParser, AFunction, PA, False);
  AssignExtended(Result, Max(GetExtended(PA[0].Value), GetExtended(PA[1].Value)));
end;

function TMathMethod.MaxValueMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const PA: TParameterArray): TValue;
var
  Parameter: TDoubleDynArray;
begin
  Check(AFunction, PA, AFunction.Method.Parameter.Count, vrBelow);
  Check(FParser, AFunction, PA, False);
  Parameter := FArray(PA, Low(PA), High(PA));
  try
    AssignExtended(Result, MaxValue(Parameter));
  finally
    Parameter := nil;
  end;
end;

function TMathMethod.MeanMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const PA: TParameterArray): TValue;
var
  Parameter: TDoubleDynArray;
begin
  Check(AFunction, PA, AFunction.Method.Parameter.Count, vrBelow);
  Check(FParser, AFunction, PA, False);
  Parameter := FArray(PA, Low(PA), High(PA));
  try
    try
      AssignExtended(Result, Mean(Parameter));
    except
      AssignExtended(Result, NaN);
    end;
  finally
    Parameter := nil;
  end;
end;

function TMathMethod.MilliSecondMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType): TValue;
var
  SystemTime: TSystemTime;
begin
  GetLocalTime(SystemTime);
  AssignWord(Result, {$IFDEF FPC}SystemTime.Millisecond{$ELSE}SystemTime.wMilliseconds{$ENDIF});
end;

function TMathMethod.MilliSecondOfMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const Value: TValue): TValue;
begin
  AssignWord(Result, MilliSecondOf(GetDouble(Value)));
end;

function TMathMethod.MilliSecondOfTheDayMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const Value: TValue): TValue;
begin
  AssignLongWord(Result, MilliSecondOfTheDay(GetDouble(Value)));
end;

function TMathMethod.MilliSecondOfTheHourMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const Value: TValue): TValue;
begin
  AssignLongWord(Result, MilliSecondOfTheHour(GetDouble(Value)));
end;

function TMathMethod.MilliSecondOfTheMinuteMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const Value: TValue): TValue;
begin
  AssignLongWord(Result, MilliSecondOfTheMinute(GetDouble(Value)));
end;

function TMathMethod.MilliSecondOfTheMonthMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const Value: TValue): TValue;
begin
  AssignLongWord(Result, MilliSecondOfTheMonth(GetDouble(Value)));
end;

function TMathMethod.MilliSecondOfTheSecondMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const Value: TValue): TValue;
begin
  AssignWord(Result, MilliSecondOfTheSecond(GetDouble(Value)));
end;

function TMathMethod.MilliSecondOfTheWeekMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const Value: TValue): TValue;
begin
  AssignLongWord(Result, MilliSecondOfTheWeek(GetDouble(Value)));
end;

function TMathMethod.MilliSecondOfTheYearMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const Value: TValue): TValue;
begin
  AssignInt64(Result, MilliSecondOfTheYear(GetDouble(Value)));
end;

function TMathMethod.MilliSecondsBetweenMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const PA: TParameterArray): TValue;
begin
  Check(AFunction, PA, AFunction.Method.Parameter.Count, vrEqual);
  Check(Parser, AFunction, PA, False);
  AssignInt64(Result, MilliSecondsBetween(GetDouble(PA[0].Value), GetDouble(PA[1].Value)));
end;

function TMathMethod.MinIntValueMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const PA: TParameterArray): TValue;
var
  Parameter: TIntegerDynArray;
begin
  Check(AFunction, PA, AFunction.Method.Parameter.Count, vrBelow);
  Check(FParser, AFunction, PA, False);
  Parameter := IArray(PA, Low(PA), High(PA));
  try
    AssignInteger(Result, MinIntValue(Parameter));
  finally
    Parameter := nil;
  end;
end;

function TMathMethod.MinMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const PA: TParameterArray): TValue;
begin
  Check(AFunction, PA, AFunction.Method.Parameter.Count);
  Check(FParser, AFunction, PA, False);
  AssignExtended(Result, Min(GetExtended(PA[0].Value), GetExtended(PA[1].Value)));
end;

function TMathMethod.MinuteMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType): TValue;
var
  SystemTime: TSystemTime;
begin
  GetLocalTime(SystemTime);
  AssignWord(Result, {$IFDEF FPC}SystemTime.Minute{$ELSE}SystemTime.wMinute{$ENDIF});
end;

function TMathMethod.MinuteOfMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const Value: TValue): TValue;
begin
  AssignWord(Result, MinuteOf(GetDouble(Value)));
end;

function TMathMethod.MinuteOfTheDayMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const Value: TValue): TValue;
begin
  AssignWord(Result, MinuteOfTheDay(GetDouble(Value)));
end;

function TMathMethod.MinuteOfTheHourMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const Value: TValue): TValue;
begin
  AssignWord(Result, MinuteOfTheHour(GetDouble(Value)));
end;

function TMathMethod.MinuteOfTheMonthMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const Value: TValue): TValue;
begin
  AssignWord(Result, MinuteOfTheMonth(GetDouble(Value)));
end;

function TMathMethod.MinuteOfTheWeekMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const Value: TValue): TValue;
begin
  AssignWord(Result, MinuteOfTheWeek(GetDouble(Value)));
end;

function TMathMethod.MinuteOfTheYearMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const Value: TValue): TValue;
begin
  AssignLongWord(Result, MinuteOfTheYear(GetDouble(Value)));
end;

function TMathMethod.MinutesBetweenMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const PA: TParameterArray): TValue;
begin
  Check(AFunction, PA, AFunction.Method.Parameter.Count, vrEqual);
  Check(Parser, AFunction, PA, False);
  AssignInt64(Result, MinutesBetween(GetDouble(PA[0].Value), GetDouble(PA[1].Value)));
end;

function TMathMethod.MinValueMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const PA: TParameterArray): TValue;
var
  Parameter: TDoubleDynArray;
begin
  Check(AFunction, PA, AFunction.Method.Parameter.Count, vrBelow);
  Check(FParser, AFunction, PA, False);
  Parameter := FArray(PA, Low(PA), High(PA));
  try
    AssignExtended(Result, MinValue(Parameter));
  finally
    Parameter := nil;
  end;
end;

function TMathMethod.ModMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const LValue, RValue: TValue): TValue;
var
  AValue, BValue: Integer;
begin
  AValue := GetInteger(LValue);
  BValue := GetInteger(RValue);
  if (etZeroDivide in TParser(FParser).ExceptionTypeSet) and (BValue = 0) then
    AssignExtended(Result, NaN)
  else
    AssignInteger(Result, AValue mod BValue);
end;

function TMathMethod.MonthMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType): TValue;
var
  SystemTime: TSystemTime;
begin
  GetLocalTime(SystemTime);
  AssignWord(Result, {$IFDEF FPC}SystemTime.Month{$ELSE}SystemTime.wMonth{$ENDIF});
end;

function TMathMethod.MonthOfMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const Value: TValue): TValue;
begin
  AssignWord(Result, MonthOf(GetDouble(Value)));
end;

function TMathMethod.MonthOfTheYearMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const Value: TValue): TValue;
begin
  AssignWord(Result, MonthOfTheYear(GetDouble(Value)));
end;

function TMathMethod.MonthsBetweenMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const PA: TParameterArray): TValue;
begin
  Check(AFunction, PA, AFunction.Method.Parameter.Count, vrEqual);
  Check(Parser, AFunction, PA, False);
  AssignInteger(Result, MonthsBetween(GetDouble(PA[0].Value), GetDouble(PA[1].Value)));
end;

function TMathMethod.NormMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const PA: TParameterArray): TValue;
var
  Parameter: TDoubleDynArray;
begin
  Check(AFunction, PA, AFunction.Method.Parameter.Count, vrBelow);
  Check(FParser, AFunction, PA, False);
  Parameter := FArray(PA, Low(PA), High(PA));
  try
    AssignExtended(Result, Norm(Parameter));
  finally
    Parameter := nil;
  end;
end;

function TMathMethod.PolyMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const PA: TParameterArray): TValue;
var
  {$IFDEF FPC}
  I: Integer;
  E, X: Extended;
  {$ELSE}
  Parameter: TDoubleDynArray;
  {$ENDIF}
begin
  {$IFDEF FPC}
  Check(AFunction, PA, AFunction.Method.Parameter.Count, vrBelow);
  Check(FParser, AFunction, PA, False);
  E := GetExtended(PA[0].Value);
  X := 0;
  for I := High(PA) downto 1 do X := X * E + GetExtended(PA[I].Value);
  AssignExtended(Result, X);
  {$ELSE}
  Check(AFunction, PA, AFunction.Method.Parameter.Count, vrBelow);
  Check(FParser, AFunction, PA, False);
  Parameter := FArray(PA, 1, High(PA));
  try
    try
      AssignExtended(Result, Poly(GetExtended(PA[0].Value), Parameter));
    except
      AssignExtended(Result, NaN);
    end;
  finally
    Parameter := nil;
  end;
  {$ENDIF}
end;

function TMathMethod.PopnStdDevMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const PA: TParameterArray): TValue;
var
  Parameter: TDoubleDynArray;
begin
  Check(AFunction, PA, AFunction.Method.Parameter.Count, vrBelow);
  Check(FParser, AFunction, PA, False);
  Parameter := FArray(PA, Low(PA), High(PA));
  try
    try
      AssignExtended(Result, PopnStdDev(Parameter));
    except
      AssignExtended(Result, NaN);
    end;
  finally
    Parameter := nil;
  end;
end;

function TMathMethod.PopnVarianceMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const PA: TParameterArray): TValue;
var
  Parameter: TDoubleDynArray;
begin
  Check(AFunction, PA, AFunction.Method.Parameter.Count, vrBelow);
  Check(FParser, AFunction, PA, False);
  Parameter := FArray(PA, Low(PA), High(PA));
  try
    try
      AssignExtended(Result, PopnVariance(Parameter));
    except
      AssignExtended(Result, NaN);
    end;
  finally
    Parameter := nil;
  end;
end;

function TMathMethod.PowerMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const LValue, RValue: TValue): TValue;
begin
  AssignExtended(Result, Power(GetExtended(LValue), GetExtended(RValue)));
end;

function TMathMethod.RadToCycleMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const Value: TValue): TValue;
begin
  AssignExtended(Result, RadToCycle(GetExtended(Value)));
end;

function TMathMethod.RadToDegMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const Value: TValue): TValue;
begin
  AssignExtended(Result, RadToDeg(GetExtended(Value)));
end;

function TMathMethod.RadToGradMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const Value: TValue): TValue;
begin
  AssignExtended(Result, RadToGrad(GetExtended(Value)));
end;

function TMathMethod.RandGMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const PA: TParameterArray): TValue;
begin
  Check(AFunction, PA, AFunction.Method.Parameter.Count);
  Check(FParser, AFunction, PA, False);
  AssignExtended(Result, RandG(GetExtended(PA[0].Value), GetExtended(PA[1].Value)));
end;

function TMathMethod.RandomFromMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const PA: TParameterArray): TValue;
var
  Parameter: TDoubleDynArray;
begin
  Check(AFunction, PA, AFunction.Method.Parameter.Count, vrBelow);
  Check(FParser, AFunction, PA, False);
  Parameter := FArray(PA, Low(PA), High(PA));
  try
    AssignExtended(Result, RandomFrom(Parameter));
  finally
    Parameter := nil;
  end;
end;

function TMathMethod.RandomMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const Value: TValue): TValue;
begin
  AssignInteger(Result, Random(GetInteger(Value)));
end;

function TMathMethod.RandomRangeMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const PA: TParameterArray): TValue;
begin
  Check(AFunction, PA, AFunction.Method.Parameter.Count);
  Check(FParser, AFunction, PA, False);
  AssignInteger(Result, RandomRange(GetInteger(PA[0].Value), GetInteger(PA[1].Value)));
end;

function TMathMethod.RootMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const LValue, RValue: TValue): TValue;
begin
  AssignExtended(Result, Power(GetExtended(LValue), 1 / GetExtended(RValue)));
end;

function TMathMethod.RoundMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const Value: TValue): TValue;
begin
  AssignExtended(Result, Round(GetExtended(Value)));
end;

function TMathMethod.RoundToMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const PA: TParameterArray): TValue;
begin
  Check(AFunction, PA, AFunction.Method.Parameter.Count);
  Check(FParser, AFunction, PA, False);
  AssignExtended(Result, RoundTo(GetExtended(PA[0].Value), TRoundToRange(GetInteger(PA[1].Value))));
end;

function TMathMethod.SameDateMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const PA: TParameterArray): TValue;
var
  P: TCustomParser;
begin
  Check(AFunction, PA, AFunction.Method.Parameter.Count, vrEqual);
  Check(Parser, AFunction, PA, False);
  P := TCustomParser(FParser);
  if SameDate(GetDouble(PA[0].Value), GetDouble(PA[1].Value)) then
    Result := P.PositiveValue
  else
    Result := P.NegativeValue;
end;

function TMathMethod.SameDateTimeMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const PA: TParameterArray): TValue;
var
  P: TCustomParser;
begin
  Check(AFunction, PA, AFunction.Method.Parameter.Count, vrEqual);
  Check(Parser, AFunction, PA, False);
  P := TCustomParser(FParser);
  if SameDateTime(GetDouble(PA[0].Value), GetDouble(PA[1].Value)) then
    Result := P.PositiveValue
  else
    Result := P.NegativeValue;
end;

function TMathMethod.SameTimeMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const PA: TParameterArray): TValue;
var
  P: TCustomParser;
begin
  Check(AFunction, PA, AFunction.Method.Parameter.Count, vrEqual);
  Check(Parser, AFunction, PA, False);
  P := TCustomParser(FParser);
  if SameTime(GetDouble(PA[0].Value), GetDouble(PA[1].Value)) then
    Result := P.PositiveValue
  else
    Result := P.NegativeValue;
end;

function TMathMethod.SecHMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const Value: TValue): TValue;
begin
  {$IFDEF FPC}
  AssignExtended(Result, SecH(GetExtended(Value)));
  {$ELSE}
  AssignExtended(Result, SecH(GetExtended(Value)));
  {$ENDIF}
end;

function TMathMethod.SecMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const Value: TValue): TValue;
var
  AValue: Double;
begin
  AValue := GetExtended(Value);
  if (etZeroDivide in TParser(FParser).ExceptionTypeSet) and IsZero(Cos(AValue)) then
    AssignExtended(Result, NaN)
  else
    AssignExtended(Result, Sec(AValue));
end;

function TMathMethod.SecondMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType): TValue;
var
  SystemTime: TSystemTime;
begin
  GetLocalTime(SystemTime);
  AssignWord(Result, {$IFDEF FPC}SystemTime.Second{$ELSE}SystemTime.wSecond{$ENDIF});
end;

function TMathMethod.SecondOfMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const Value: TValue): TValue;
begin
  AssignWord(Result, SecondOf(GetDouble(Value)));
end;

function TMathMethod.SecondOfTheDayMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const Value: TValue): TValue;
begin
  AssignLongWord(Result, SecondOfTheDay(GetDouble(Value)));
end;

function TMathMethod.SecondOfTheHourMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const Value: TValue): TValue;
begin
  AssignWord(Result, SecondOfTheHour(GetDouble(Value)));
end;

function TMathMethod.SecondOfTheMinuteMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const Value: TValue): TValue;
begin
  AssignWord(Result, SecondOfTheMinute(GetDouble(Value)));
end;

function TMathMethod.SecondOfTheMonthMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const Value: TValue): TValue;
begin
  AssignLongWord(Result, SecondOfTheMonth(GetDouble(Value)));
end;

function TMathMethod.SecondOfTheWeekMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const Value: TValue): TValue;
begin
  AssignLongWord(Result, SecondOfTheWeek(GetDouble(Value)));
end;

function TMathMethod.SecondOfTheYearMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const Value: TValue): TValue;
begin
  AssignLongWord(Result, SecondOfTheYear(GetDouble(Value)));
end;

function TMathMethod.SecondsBetweenMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const PA: TParameterArray): TValue;
begin
  Check(AFunction, PA, AFunction.Method.Parameter.Count, vrEqual);
  Check(Parser, AFunction, PA, False);
  AssignInt64(Result, SecondsBetween(GetDouble(PA[0].Value), GetDouble(PA[1].Value)));
end;

function TMathMethod.SinHMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const Value: TValue): TValue;
begin
  AssignExtended(Result, SinH(GetExtended(Value)));
end;

function TMathMethod.SinMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const Value: TValue): TValue;
begin
  AssignExtended(Result, Sin(GetExtended(Value)));
end;

function TMathMethod.SqrMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const Value: TValue): TValue;
begin
  Check(Value.ValueType);
  case Value.ValueType of
    vtByte: AssignDouble(Result, Sqr(Value.Unsigned8));
    vtShortint: AssignDouble(Result, Sqr(Value.Signed8));
    vtWord: AssignDouble(Result, Sqr(Value.Unsigned16));
    vtSmallint: AssignDouble(Result, Sqr(Value.Signed16));
    vtLongWord: AssignDouble(Result, Sqr(Value.Unsigned32));
    vtInteger: AssignDouble(Result, Sqr(Value.Signed32));
    vtNativeInt: AssignDouble(Result, Sqr(Value.NativeInt));
    vtNativeUInt: AssignDouble(Result, Sqr(Value.NativeUInt));
    vtInt64: AssignDouble(Result, Sqr(Value.Signed64));
    vtSingle: AssignDouble(Result, Sqr(Value.Float32));
    vtDouble: AssignDouble(Result, Sqr(Value.Float64));
    vtExtended: AssignExtended(Result, Sqr(Value.Float80));
  end;
end;

function TMathMethod.SqrtMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const Value: TValue): TValue;
begin
  Check(Value.ValueType);
  case Value.ValueType of
    vtByte: AssignDouble(Result, Sqrt(Value.Unsigned8));
    vtShortint: AssignDouble(Result, Sqrt(Value.Signed8));
    vtWord: AssignDouble(Result, Sqrt(Value.Unsigned16));
    vtSmallint: AssignDouble(Result, Sqrt(Value.Signed16));
    vtLongWord: AssignDouble(Result, Sqrt(Value.Unsigned32));
    vtInteger: AssignDouble(Result, Sqrt(Value.Signed32));
    {$IFDEF DELPHI_2005}
    vtNativeInt: AssignDouble(Result, Sqrt(Value.NativeInt));
    {$ELSE}
    vtNativeInt: AssignDouble(Result, Sqrt(Value.Signed32));
    {$ENDIF}
    {$IFDEF DELPHI_2005}
    vtNativeUInt: AssignDouble(Result, Sqrt(Value.NativeUInt));
    {$ELSE}
    vtNativeUInt: AssignDouble(Result, Sqrt(Value.Signed32));
    {$ENDIF}
    {$IFDEF DELPHI_2005}
    vtInt64: AssignDouble(Result, Sqrt(Value.Signed64));
    {$ELSE}
    vtInt64: AssignDouble(Result, Sqrt(Value.Signed32));
    {$ENDIF}
    {$IFDEF DELPHI_2005}
    vtSingle: AssignDouble(Result, Sqrt(Value.Float32));
    {$ELSE}
    vtSingle: AssignDouble(Result, Sqrt(Value.Float32));
    {$ENDIF}
    {$IFDEF DELPHI_2005}
    vtDouble: AssignDouble(Result, Sqrt(Value.Float64));
    {$ELSE}
    vtDouble: AssignDouble(Result, Sqrt(Value.Float64));
    {$ENDIF}
    {$IFDEF DELPHI_2005}
    vtExtended: AssignExtended(Result, Sqrt(Value.Float80));
    {$ELSE}
    vtExtended: AssignExtended(Result, Sqrt(Value.Float80));
    {$ENDIF}
  end;
end;

function TMathMethod.StdDevMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const PA: TParameterArray): TValue;
var
  Parameter: TDoubleDynArray;
begin
  Check(AFunction, PA, AFunction.Method.Parameter.Count, vrBelow);
  Check(FParser, AFunction, PA, False);
  Parameter := FArray(PA, Low(PA), High(PA));
  try
    try
      AssignExtended(Result, StdDev(Parameter));
    except
      AssignExtended(Result, NaN);
    end;
  finally
    Parameter := nil;
  end;
end;

function TMathMethod.StrToDateMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const PA: TParameterArray): TValue;
begin
  Check(AFunction, PA, AFunction.Method.Parameter.Count, vrEqual);
  Check(FParser, AFunction, 0, PA[0].THandle, True);
  AssignDouble(Result, StrToDate(CleanDateTime(PA[0].Text)));
end;

function TMathMethod.StrToDateTimeMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const PA: TParameterArray): TValue;
begin
  Check(AFunction, PA, AFunction.Method.Parameter.Count, vrEqual);
  Check(FParser, AFunction, 0, PA[0].THandle, True);
  AssignDouble(Result, StrToDateTime(CleanDateTime(PA[0].Text)));
end;

function TMathMethod.StrToTimeMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const PA: TParameterArray): TValue;
begin
  Check(AFunction, PA, AFunction.Method.Parameter.Count, vrEqual);
  Check(FParser, AFunction, 0, PA[0].THandle, True);
  AssignDouble(Result, StrToTime(CleanDateTime(PA[0].Text)));
end;

function TMathMethod.SumIntMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const PA: TParameterArray): TValue;
var
  Parameter: TIntegerDynArray;
begin
  Check(AFunction, PA, AFunction.Method.Parameter.Count, vrBelow);
  Check(FParser, AFunction, PA, False);
  Parameter := IArray(PA, Low(PA), High(PA));
  try
    try
      AssignExtended(Result, SumInt(Parameter));
    except
      AssignExtended(Result, NaN);
    end;
  finally
    Parameter := nil;
  end;
end;

function TMathMethod.SumMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const PA: TParameterArray): TValue;
var
  Parameter: TDoubleDynArray;
begin
  Check(AFunction, PA, AFunction.Method.Parameter.Count, vrBelow);
  Check(FParser, AFunction, PA, False);
  Parameter := FArray(PA, Low(PA), High(PA));
  try
    try
      AssignExtended(Result, Sum(Parameter));
    except
      AssignExtended(Result, NaN);
    end;
  finally
    Parameter := nil;
  end;
end;

function TMathMethod.SumOfSquaresMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const PA: TParameterArray): TValue;
var
  Parameter: TDoubleDynArray;
begin
  Check(AFunction, PA, AFunction.Method.Parameter.Count, vrBelow);
  Check(FParser, AFunction, PA, False);
  Parameter := FArray(PA, Low(PA), High(PA));
  try
    AssignExtended(Result, SumOfSquares(Parameter));
  finally
    Parameter := nil;
  end;
end;

function TMathMethod.TanHMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const Value: TValue): TValue;
begin
  AssignExtended(Result, TanH(GetExtended(Value)));
end;

function TMathMethod.TanMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const Value: TValue): TValue;
var
  AValue: Double;
begin
  AValue := GetExtended(Value);
  if (etZeroDivide in TParser(FParser).ExceptionTypeSet) and IsZero(Cos(AValue)) then
    AssignExtended(Result, NaN)
  else
    AssignExtended(Result, Tan(AValue));
end;

function TMathMethod.TimeMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType): TValue;
begin
  AssignDouble(Result, Time);
end;

function TMathMethod.TimeOfMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const Value: TValue): TValue;
begin
  AssignDouble(Result, TimeOf(GetDouble(Value)));
end;

function TMathMethod.TotalVarianceMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const PA: TParameterArray): TValue;
var
  Parameter: TDoubleDynArray;
begin
  Check(AFunction, PA, AFunction.Method.Parameter.Count, vrBelow);
  Check(FParser, AFunction, PA, False);
  Parameter := FArray(PA, Low(PA), High(PA));
  try
    try
      AssignExtended(Result, TotalVariance(Parameter));
    except
      AssignExtended(Result, NaN);
    end;
  finally
    Parameter := nil;
  end;
end;

function TMathMethod.TruncMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const Value: TValue): TValue;
begin
  AssignExtended(Result, Trunc(GetExtended(Value)));
end;

function TMathMethod.VarianceMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const PA: TParameterArray): TValue;
var
  Parameter: TDoubleDynArray;
begin
  Check(AFunction, PA, AFunction.Method.Parameter.Count, vrBelow);
  Check(FParser, AFunction, PA, False);
  Parameter := FArray(PA, Low(PA), High(PA));
  try
    try
      AssignExtended(Result, Variance(Parameter));
    except
      AssignExtended(Result, NaN);
    end;
  finally
    Parameter := nil;
  end;
end;

function TMathMethod.WeekOfMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const Value: TValue): TValue;
begin
  AssignWord(Result, WeekOf(GetDouble(Value)));
end;

function TMathMethod.WeekOfTheMonthMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const Value: TValue): TValue;
begin
  AssignWord(Result, WeekOfTheMonth(GetDouble(Value)));
end;

function TMathMethod.WeekOfTheYearMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const Value: TValue): TValue;
begin
  AssignWord(Result, WeekOfTheYear(GetDouble(Value)));
end;

function TMathMethod.WeeksBetweenMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const PA: TParameterArray): TValue;
begin
  Check(AFunction, PA, AFunction.Method.Parameter.Count, vrEqual);
  Check(Parser, AFunction, PA, False);
  AssignInteger(Result, WeeksBetween(GetDouble(PA[0].Value), GetDouble(PA[1].Value)));
end;

function TMathMethod.YearMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType): TValue;
var
  SystemTime: TSystemTime;
begin
  GetLocalTime(SystemTime);
  AssignWord(Result, {$IFDEF FPC}SystemTime.Year{$ELSE}SystemTime.wYear{$ENDIF});
end;

function TMathMethod.YearOfMethod(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const Value: TValue): TValue;
begin
  AssignWord(Result, YearOf(GetDouble(Value)));
end;

function TMathMethod.YearsBetweenMethod(const Header: PScriptHeader; const AFunction: PFunction;
  const AType: PType; const PA: TParameterArray): TValue;
begin
  Check(AFunction, PA, AFunction.Method.Parameter.Count, vrEqual);
  Check(Parser, AFunction, PA, False);
  AssignInteger(Result, YearsBetween(GetDouble(PA[0].Value), GetDouble(PA[1].Value)));
end;

initialization
  {$IFDEF FPC}
  InitCriticalSection(MethodSync);
  {$ELSE}
  InitializeCriticalSection(MethodSync);
  {$ENDIF}

finalization
  {$IFDEF FPC}
  DoneCriticalSection(MethodSync);
  {$ELSE}
  DeleteCriticalSection(MethodSync);
  {$ENDIF}

end.
