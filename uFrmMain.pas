unit uFrmMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ToolWin, Vcl.ComCtrls, Vcl.StdCtrls,
  Vcl.ExtCtrls, Generics.Collections;

type
  TUserProp = class
  private
    FCode: string;
    FDuty: string;
    FUser: string;
  protected
  public
  end;

  TfrmMain = class(TForm)
    Memo1: TMemo;
    memoDetail: TMemo;
    Button1: TButton;
    ToolBar1: TToolBar;
    edtStartLines: TEdit;
    ToolButton1: TToolButton;
    ToolButton2: TToolButton;
    edtUserDuty: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Splitter1: TSplitter;
    StatusBar1: TStatusBar;
    UpDown1: TUpDown;
    Panel1: TPanel;
    Splitter2: TSplitter;
    memoUser: TMemo;
    UpDown2: TUpDown;
    ToolButton3: TToolButton;
    DateTimePicker1: TDateTimePicker;
    Label3: TLabel;
    Splitter3: TSplitter;
    Memo2: TMemo;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
    // 2018-07-01, riverbo, 上午/下午, 08:00:00 / 17:00:00
    FDayUserOvMap: TDictionary<String, TDictionary<String, TDictionary<String, String>>>;
    FUserMaps: TDictionary<String, TUserProp>;
    //
    procedure doPrepare;
    function strs2file(const strs: TStrings; const f: string): boolean;
  public
    { Public declarations }
    function wirteFile(const bWrite: boolean): string;
  end;

var
  frmMain: TfrmMain;

implementation

uses uCharSplit, IniFiles;

{$R *.dfm}

procedure TfrmMain.Button1Click(Sender: TObject);

  function spinStr(const S: string; var dateV, timeV: string): boolean;
  var i: integer;
  begin
    i := s.IndexOf(' ');
    if i>=0 then begin
      dateV := S.Substring(0, i);
      timeV := S.Substring(i);
      Result := true;
    end else begin
      Result := false;
    end;
  end;

  function doItSpin(const S: string; var userKey, dateV, timeV: string): boolean;

  var
    strs: TStrings;
    dateTimeV: string;
  begin
    Result := false;
    strs := TStringList.Create;
    try
      TCharSplit.SplitChar(S, #9, strs);
      if strs.Count>=10 then begin
        userKey := strs[1];
        dateTimeV := strs[5];
        spinStr(dateTimeV, dateV, timeV);
        //if compateDTime(dateTimeV) then begin
          Result := true;
        //end;
      end;
    finally
      strs.Free;
    end;
  end;

  {function strToMap2(const S: string): integer;
  var userKey, dateV, timeV: string;
    userMap: TDictionary<String, String>;
    vValue: string;
  begin
    Result := 0;
    if (doItSpin(S, userKey, dateV, timeV)) then begin
      if not FMap.TryGetValue(dateV, userMap) then begin
        userMap := TDictionary<String, TDictionary<String, String>>.create;
      end;
      if not userMap.TryGetValue(userKey, vValue) then begin
        vValue := timeV;
      end else begin
        vValue := vValue + ';' + timeV;
      end;
      userMap.AddOrSetValue(userKey, vValue);
      FMap.AddOrSetValue(dateV, userMap);
      Inc(Result);
    end;
  end;}

  function getAm(const tm: string): string;
  var
    strs: TStrings;
    hour: integer;
  begin
    Result := '';
    strs := TStringList.Create;
    try
      TCharSplit.SplitChar(tm, ':', strs);
      if strs.Count>=3 then begin
        hour := StrToInt(strs[0]);
        if hour<12 then begin
          Result := 'am';
        end else begin
          Result := 'pm';
        end;
      end;
    finally
      strs.Free;
    end;
  end;

  function strToMap(const S: string): integer;
  var userKey, dateV, timeV: string;
    userMap: TDictionary<String, TDictionary<String, String>>;
    amMap: TDictionary<String, String>;
    //vValue: string;
    bAdd: boolean;
    am: string;
  begin
    Result := 0;
    if (doItSpin(S, userKey, dateV, timeV)) then begin
      if not FDayUserOvMap.TryGetValue(dateV, userMap) then begin
        userMap := TDictionary<String, TDictionary<String, String>>.create;
      end;
      bAdd := false;
      am := getAm(timeV);
      if not userMap.TryGetValue(userKey, amMap) then begin
        amMap := TDictionary<String, String>.create();
        amMap.Add(am, timeV);
        bAdd := true;
      end else begin
        //if not amMap.TryGetValue(am, vValue) then begin
        if am.Equals('am') then begin                // am , put always
          amMap.AddOrSetValue(am, timeV);
          bAdd := true;
        end else if am.Equals('pm') then begin       // pm, put once
          if not amMap.ContainsKey(am) then begin
            amMap.Add(am, timeV);
          end;
        end;
      end;
      if bAdd then begin
        userMap.AddOrSetValue(userKey, amMap);
        FDayUserOvMap.AddOrSetValue(dateV, userMap);
        Inc(Result);
      end;
    end;
  end;

  function compateDTime(const dateV: string; const dateTimeV: string;
    const ovTime: string): boolean;

    {function getTimeStr(const dateTimeV: string): string;
    var ss: string;
    begin
      //ss := TimeToStr(dateTimePicker1.Time);
      Result := SS;
    end;}

  var vOvertime, dtRec: TDateTime;
  begin
    dtRec := VarToDateTime(dateV + ' ' + dateTimeV);
    vOvertime := VarToDateTime(dateV + ' ' + ovTime);
    if (dtRec>=vOvertime) then begin
      Result := true;
    end else begin
      Result := false;
    end;
  end;

  procedure mapToLines(map: TDictionary<String, TDictionary<String, TDictionary<String, String>>>; strs: TStrings);

      function bool2str(const b: boolean): string;
      begin
        if b then begin
          Result := '1';
        end else begin
          Result := '0';
        end;
      end;

      function amMapToLines(const dateV: string; const userName: string;
        amMap: TDictionary<String, String>; const u: TUserProp): boolean;
      var sql: String;
        key, val, ovStrTime, ovStrTimes: String;
        ovTime: string;
      begin
        ovStrTimes := '';
        ovStrTime := '';
        for Key in amMap.Keys do begin
          val := amMap[key];
          if key.Equals('pm') then begin
            ovStrTime := val;
          end;
          if (ovStrTimes.IsEmpty()) then begin
            ovStrTimes := val;
          end else begin
            ovStrTimes := val + ';' + ovStrTimes;
          end;
        end;
        //
        if compateDTime(dateV, ovStrTime, TimeToStr(dateTimePicker1.Time)) then begin
          Result := true;
        end else begin
          Result := false;
        end;
        //
        ovTime := bool2str(Result);
        if (u<>nil) then begin
          sql := dateV + #9 + u.FCode + #9 + userName + #9 + u.FDuty + #9 +
            ovStrTimes + #9 + ovTime;
        end else begin
          sql := dateV + #9 + '-' + #9 + userName + #9 + '-' + #9 +
            ovStrTimes + #9 + ovTime;
        end;
        //
        strs.Insert(0, sql);
      end;

    function mapToLineD(const dateV: string; M: TDictionary<String, TDictionary<String, String>>;
      var persons: integer): string;
    var key, userName: String;
      u: TUserProp;
      bOvTime: boolean;
      ovTimeUsers: integer;
    begin
      Result := '';
      ovTimeUsers := 0;
      // 2018-07-01, riverbo, 上午/下午, 08:00:00 / 17:00:00
      for Key in M.Keys do begin
        userName := Key;
        //
        u := nil;
        // FUserMaps
        FUserMaps.TryGetValue(userName, u);
        //amMapToLines(userName, amMap);
        bOvTime := amMapToLines(dateV, userName, M[Key], u);
        if bOvTime then begin
          Inc(ovTimeUsers);
          //
          if Result.IsEmpty then begin
            Result := userName;
          end else begin
            Result := Result + #9 + userName;
          end;
        end;
      end;
      if ovTimeUsers>0 then begin
        persons := persons + ovTimeUsers;
        Result := dateV + #9 + IntToStr(ovTimeUsers) + #9 + '' + #9 + Result;
      end;
    end;

  var key, dateV, detailStr: String;
    userMap: TDictionary<String, TDictionary<String, String>>;
    persons: integer;
  begin
    // 2018-07-01, riverbo, 上午/下午, 08:00:00 / 17:00:00
    persons := 0;
    for Key in map.Keys do begin
      userMap := map[Key];
      dateV := key;
      detailStr := mapToLineD(dateV, userMap, persons);
      if not detailStr.IsEmpty then begin
        MemoDetail.Lines.Insert(0, detailStr);
      end;
    end;
    MemoDetail.Lines.Add('合计:' + #9 + IntToStr(persons));
  end;

var i, start: integer;
  S: string;
begin
  FDayUserOvMap.clear;
  FUserMaps.clear;
  MemoDetail.Clear;
  //
  Memo2.Clear;
  //
  doPrepare();
  //
  start := StrToInt(edtStartLines.Text);
  for I := start to self.Memo1.Lines.Count - 1 do begin
    S := memo1.lines[I];
    if not S.Trim.IsEmpty then begin
      strToMap(S);
    end;
  end;
  // show map
  mapToLines(FDayUserOvMap, Memo2.Lines);
  //
  Memo2.Lines.insert(0, '考勤日期' + #9 + '员工编码' + #9 + '姓名' + #9 + '职位' + #9 + '打卡记录' + #9 + '加班');
  Memo2.Lines.insert(0, '出勤记录列表');
  //
  MemoDetail.Lines.insert(0, '日期' + #9 + '加班人数' + #9 + '餐费' + #9 + '加班名单' + #9 + '人均餐费');
  MemoDetail.Lines.insert(0, '餐费明细列表');
  //
  self.strs2file(Memo2.Lines, '出勤记录列表.csv');
  self.strs2file(MemoDetail.Lines, '餐费明细列表.csv');
end;

procedure TfrmMain.doPrepare();

  procedure initUserDuty(strs: TStrings);

    function doItPer(const S: string): boolean;
    var
      strs: TStrings;
      userName: string;
      u: TUserProp;
    begin
      Result := false;
      strs := TStringList.Create;
      u := TUserProp.Create;
      try
        TCharSplit.SplitChar(S, #9, strs);
        if strs.Count>=3 then begin
          userName := strs[1].Trim;
          if not FUserMaps.ContainsKey(userName) then begin
            u.FCode := strs[0];
            u.FUser := userName;
            u.FDuty := strs[2];
            FUserMaps.AddOrSetValue(u.FUser, u);
            //
            Result := true;
          end;
        end;
      finally
        strs.Free;
      end;
    end;
  var S: string;
    i, start: integer;
  begin
    start := StrToInt(edtUserDuty.Text);
    for I := start to strs.Count - 1 do begin
      S := strs[I];
      if not S.Trim.IsEmpty then begin
        doItPer(S);
      end;
    end;
  end;
begin
  initUserDuty(memoUser.Lines);
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  FDayUserOvMap := TDictionary<String, TDictionary<String, TDictionary<String, String>>>.create;
  FUserMaps := TDictionary<String, TUserProp>.create;
  //
  //self.DateTimePicker1.c('yyyy-MM-dd HH:mm:ss');
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  FDayUserOvMap.Free;
  FUserMaps.Free;
end;

procedure TfrmMain.FormShow(Sender: TObject);
begin
  self.WindowState := wsMaximized;
end;

function TfrmMain.wirteFile(const bWrite: boolean): string;
var FName: string;
  myinifile: Tinifile;
begin
  //FName := TFileUtils.mergeAppPath('init.txt');
  FName := ExtractFilePath(Paramstr(0))+'setting.ini';
  myinifile := Tinifile.Create(FName);
  try
    if bWrite then begin
      //TFileUtils.WriteToFile(, FName);
      myinifile.Writestring('line','recNo',self.edtStartLines.Text);
      myinifile.Writestring('line','userDutyNo',self.edtStartLines.Text);
      //self.edtUserDuty.Text := myinifile.Readstring('line','userNo','2');
    end else begin
      self.edtStartLines.Text := myinifile.Readstring('line','recNo','2');
      self.edtUserDuty.Text := myinifile.Readstring('line','userNo','2');
    end;
  finally
    myinifile.Free;
  end;
end;

function TfrmMain.strs2file(const strs: TStrings; const f: string): boolean;
var FName: string;
begin
  FName := ExtractFilePath(Paramstr(0)) + f;
  strs.SaveToFile(fName, TEncoding.UTF8);
  Result := true;
end;

end.

