unit FnHook;

{$mode delphi}

interface

uses
  Classes, SysUtils,
  Unicorn_dyn , UnicornConst, X86Const,
  Generics.Collections,Generics.Defaults,
  {$I besenunits.inc},JSPlugins_BEngine;

type

  TFnCallBack = function( uc : uc_engine; Address , ret : UInt64 ) : Boolean; stdcall;

  { TLibFunction }
  TLibFunction = record
      Hits : Integer; // how many times this API called .
      IsForwarder, IsOrdinal : Boolean;
      LibName,
      FuncName,
      FWName : string;
      VAddress : UInt64;
      ordinal : UInt32;
      UserData : PQWord; // Pointer to user data .
      Return : Int64; // Return Adddress of the API - used to call the OnExit .
      class function Create(const LibName, FnName : string;
            VAddr : UInt64;
            Ordinal : UInt32;
            UserData : PQWord;
            FIsForwarder, IsOrdinal : Boolean;
            FWName : string): TLibFunction; static;
  end;

  { THookFunction }
  THookFunction = record
    LibName, FuncName : String;
    ordinal : UInt32;
    IsOrdinal : Boolean;
    API : TLibFunction;
    NativeCallBack : Pointer;
    JSHook : TNewHook;
    class function Create(const LibName, FnName : string;
          Ordinal : UInt32;
          IsOrdinal : Boolean = False;
          NCallBack : Pointer = nil; // Native Callback - next version .
          JSHook : TNewHook = nil): THookFunction; static;
  end;

  { TNewDll }

  TNewDll = record
    Dllname,
    Path,
    version      : string;
    EntryPoint,
    BaseAddress  : UInt64;
    ImageSize    : UInt32;

    HookBase, HookEnd : UInt64;

    { i don't remember why i put this variable here :V }
    //MemPtr       : PQWord; // use PQWORD instead of Pointer just in case someone compile to x32 .

    // < FnAddress, HookSetting >

    FnByAddr    : TFastHashMap<UInt64, TLibFunction>;
    FnByOrdinal : TFastHashMap<UInt64, TLibFunction>;
    FnByName    : TFastHashMap<String, TLibFunction>;

    class function Create(EntryPoint : UInt64; const LibName : string; FBaseAddress : UInt64;
                   FImageSize : UInt32;
                   ByAddr : TFastHashMap<UInt64, TLibFunction>;
                   ByOrdinal : TFastHashMap<UInt64, TLibFunction>;
                   ByName : TFastHashMap<String, TLibFunction>): TNewDll; static;
  end;

implementation

{ THookFunction }

class function THookFunction.Create(
          const LibName, FnName : string;
          Ordinal : UInt32;
          IsOrdinal : Boolean = False;
          NCallBack : Pointer = nil; // Native Callback - next version .
          JSHook : TNewHook = nil): THookFunction;
begin
  Result.LibName        := LibName;
  Result.FuncName       := FnName;
  Result.IsOrdinal      := IsOrdinal;
  Result.ordinal        := Ordinal;
  Result.JSHook         := JSHook;
  Result.nativeCallBack := NCallBack;
end;

class function TLibFunction.Create(
            const LibName, FnName : string;
            VAddr : UInt64;
            Ordinal : UInt32;
            UserData : PQWord;
            FIsForwarder, IsOrdinal : Boolean;
            FWName : string): TLibFunction;
begin
  Result.Hits           := 0;
  Result.Return         := 0;
  Result.IsForwarder    := FIsForwarder;
  Result.IsOrdinal      := IsOrdinal;
  Result.FWName         := FWName;
  Result.LibName        := LibName;
  Result.FuncName       := FnName;
  Result.VAddress       := VAddr;
  Result.ordinal        := Ordinal;
  Result.UserData       := UserData;
end;

class function TNewDll.Create(EntryPoint : UInt64; const LibName : string; FBaseAddress : UInt64;
                   FImageSize : UInt32;
                   ByAddr : TFastHashMap<UInt64, TLibFunction>;
                   ByOrdinal : TFastHashMap<UInt64, TLibFunction>;
                   ByName : TFastHashMap<String, TLibFunction>): TNewDll; static;
begin
  Result.EntryPoint  := EntryPoint;
  Result.Dllname     := LibName;
  Result.BaseAddress := FBaseAddress;
  Result.ImageSize   := FImageSize;
  Result.FnByAddr    := ByAddr;
  Result.FnByOrdinal := ByOrdinal;
  Result.FnByName    := ByName;
end;

end.

