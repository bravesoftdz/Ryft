unit Ryft;

{*******************************************************}
{                                                       }
{                         Ryft                          }
{                                                       }
{      Delphi Interfaces for Ryft payment gateway       }
{                                                       }
{*******************************************************}

interface

uses Classes, System.Generics.Collections;

type                               
  TMetaDataItem = record
    FName: string;
    FValue: string;
  end;

  TRequiredAction = record
    FType: string;
    FURL: string;
  end;

  TRyftStatementDescriptor = record
    FDescriptor: string;
    FCity: string;
  end;

  IRyftPaymentSession = interface
    ['{7EEA771B-7310-4BC4-AD94-A2E3DFB5891E}']
    function GetAmount: integer;
    function GetCurrency: string;
    function GetID: string;
    function GetMetaData: TList<TMetaDataItem>;
    function GetPlatformFee: integer;
    function GetStatus: string;
    function GetCustomerEmail: string;
    function GetClientSecret: string;
    function GetLastError: string;
    function GetRefundedAmount: integer;
    function GetCreatedTimeStamp: TDateTime;
    function GetLastUpdatedTimeStamp: TDateTime;
    function GetRequiredAction: TRequiredAction;
    function GetReturnURL: string;
    function GetStatementDescriptor: TRyftStatementDescriptor;
    procedure LoadFromJson(AJsonData: string);
    property ID: string read GetID;
    property Amount: integer read GetAmount;
    property Currency: string read GetCurrency;
    property CustomerEmail: string read GetCustomerEmail;
    property PlatformFee: integer read GetPlatformFee;
    property MetaData: TList<TMetaDataItem> read GetMetaData;
    property Status: string read GetStatus;
    property ClientSecret: string read GetClientSecret;
    property LastError: string read GetLastError;
    property RefundedAmount: integer read GetRefundedAmount;
    property StatementDescriptor: TRyftStatementDescriptor read GetStatementDescriptor;
    property RequiredAction: TRequiredAction read GetRequiredAction;
    property ReturnURL: string read GetReturnURL;
    property CreatedTimeStamp: TDateTime read GetCreatedTimeStamp;
    property LastUpdatedTimeStamp: TDateTime read GetLastUpdatedTimeStamp;
  end;

  IRyft = interface
    ['{595E0D33-0E92-4DA7-B699-D4C9E9E8768A}']
    function CreatePaymentSession(AAmount: integer;
                                  ACurrency: string;
                                  ACustomerEmail: string;
                                  APlatformFee: integer;
                                  const ALinkedAccount: string = '';
                                  const APassThroughFee: Boolean = False;
                                  const AMetaData: TStrings = nil;
                                  const AStatementDescriptor: string = '';
                                  const AReturnURL: string = ''): IRyftPaymentSession;

    function GetPaymentSession(APaymentID: string; const ALinkedAccount: string = ''): IRyftPaymentSession;
    function UpdatePaymentSession(APaymentID: string;
                                  const ALinkedAccount: string = '';
                                  const AAmount: integer = -1;
                                  const ACurrency: string = '';
                                  const ACustomerEmail: string = '';
                                  const APlatFormFee: integer = -1;
                                  const AMetaData: TStrings = nil): IRyftPaymentSession;
  end;

  function CreateRyft(APrivateKey: string; const ASandBox: Boolean = False): IRyft;

implementation

uses Net.HttpClient, Net.URLClient, NetConsts, JsonDataObjects, SysUtils, DateUtils;

const
  C_ENDPOINT = 'https://api.ryftpay.com/v1/';
  C_ENDPOINT_SANDBOX = 'https://sandbox-api.ryftpay.com/v1/';

type
  TRyftPaymentSession = class(TInterfacedObject, IRyftPaymentSession)
  private
    FID: string;
    FAmount: integer;
    FCurrency: string;
    FCustomerEmail: string;
    FPlatformFee: integer;
    FMetaData: TList<TMetaDataItem>;
    FStatus: string;
    FClientSecret: string;
    FLastError: string;
    FRefundedAmount: integer;
    FStatementDescriptor: TRyftStatementDescriptor;
    FRequiredAction: TRequiredAction;
    FReturnUrl: string;
    FCreatedTimeStamp: TDateTime;
    FLastUpdatedTimeStamp: TDateTime;
    function GetAmount: integer;
    function GetCurrency: string;
    function GetID: string;
    function GetMetaData: TList<TMetaDataItem>;
    function GetPlatformFee: integer;
    function GetStatus: string;
    function GetCustomerEmail: string;
    function GetClientSecret: string;
    function GetLastError: string;
    function GetRefundedAmount: integer;
    function GetCreatedTimeStamp: TDateTime;
    function GetLastUpdatedTimeStamp: TDateTime;
    function GetRequiredAction: TRequiredAction;
    function GetReturnURL: string;
    function GetStatementDescriptor: TRyftStatementDescriptor;
  protected
    procedure LoadFromJson(AJsonData: string);
  public
    constructor Create; virtual;
    destructor Destroy; override;

  end;


  TRyft = class(TInterfacedObject, IRyft)
  private
    FPrivateKey: string;
    FSandbox: Boolean;
    function GetEndpoint: string;
    function CreateHttp: THTTPClient;
    function GetHttp(AResource: string; const ALinkedAccount: string = ''): IHTTPResponse;
    function PostHttp(AResource, AData: string; const ALinkedAccount: string = ''): IHTTPResponse;
    function PatchHttp(AResource, AData: string; const ALinkedAccount: string = ''): IHTTPResponse;
  protected
    function CreatePaymentSession(AAmount: integer;
                                  ACurrency: string;
                                  ACustomerEmail: string;
                                  APlatformFee: integer;
                                  const ALinkedAccount: string = '';
                                  const APassThroughFee: Boolean = False;
                                  const AMetaData: TStrings = nil;
                                  const AStatementDescriptor: string = '';
                                  const AReturnURL: string = ''): IRyftPaymentSession;
    function GetPaymentSession(APaymentID: string; const ALinkedAccount: string = ''): IRyftPaymentSession;
    function UpdatePaymentSession(APaymentID: string;
                                  const ALinkedAccount: string = '';
                                  const AAmount: integer = -1;
                                  const ACurrency: string = '';
                                  const ACustomerEmail: string = '';
                                  const APlatFormFee: integer = -1;
                                  const AMetaData: TStrings = nil): IRyftPaymentSession;

  public
    constructor Create(APrivateKey: string; const ASandBox: Boolean = False);
    destructor Destroy; override;
  end;


function CreateRyft(APrivateKey: string; const ASandBox: Boolean = False): IRyft;
begin
  Result := TRyft.Create(APrivateKey, ASandBox);
end;


{ TRyft }

constructor TRyft.Create(APrivateKey: string; const ASandBox: Boolean = False);
begin
  FPrivateKey := APrivateKey;
  FSandBox := ASandBox;
end;

function TRyft.CreateHttp: THTTPClient;
begin
  Result := THTTPClient.Create;
  Result.CustomHeaders['Authorization'] := FPrivateKey;
  Result.ContentType := 'application/json';
end;

function TRyft.CreatePaymentSession(AAmount: integer;
                                    ACurrency: string;
                                    ACustomerEmail: string;
                                    APlatformFee: integer;
                                    const ALinkedAccount: string = '';
                                    const APassThroughFee: Boolean = False;
                                    const AMetaData: TStrings = nil;
                                    const AStatementDescriptor: string = '';
                                    const AReturnURL: string = ''): IRyftPaymentSession;

var
  AJson: TJSONObject;
  AData: string;
  ICount: integer;
begin
  Result := TRyftPaymentSession.Create;
  AJson := TJsonObject.Create;
  try
    AJson.S['amount'] := IntToStr(AAmount);
    AJson.S['currency'] := ACurrency;
    AJson.S['customerEmail'] := ACustomerEmail;
    if AReturnURL <> '' then AJson.S['returnURL'] := AReturnURL;
    if APlatformFee > 0 then AJson.S['platformFee'] := IntToStr(APlatformFee);
    if AMetaData <> nil then
    begin
      for ICount := 0 to AMetaData.Count-1 do
      begin
        AJson.O['metadata'].S[AMetaData.Names[ICount]] := AMetaData.ValueFromIndex[ICount];
        if ICount = 4 then
          Break;
      end;
    end;
    AData := PostHttp('payment-sessions', AJson.ToJSON, ALinkedAccount).ContentAsString;
    Result.LoadFromJson(AData);
  finally
    AJson.Free;
  end;
end;

function TRyft.GetPaymentSession(APaymentID: string; const ALinkedAccount: string = ''): IRyftPaymentSession;
var
  AData: string;
begin
  Result := TRyftPaymentSession.Create;
  AData := Gethttp('payment-sessions/'+APaymentID, ALinkedAccount).ContentAsString;
  Result.LoadFromJson(AData);
end;

destructor TRyft.Destroy;
begin
  inherited;
end;

function TRyft.GetEndpoint: string;
begin
  case FSandBox of
    True  : Result := C_ENDPOINT_SANDBOX;
    False : Result := C_ENDPOINT;
  end;
end;

function TRyft.GetHttp(AResource: string; const ALinkedAccount: string = ''): IHTTPResponse;
var
  AHttp: THTTPClient;
begin
  AHttp := CreateHttp;
  try
    if ALinkedAccount <> '' then
      AHttp.CustomHeaders['account'] := ALinkedAccount;

    Result := AHttp.Get(GetEndpoint+AResource);

  finally
    AHttp.Free;
  end;
end;

function TRyft.PostHttp(AResource, AData: string; const ALinkedAccount: string = ''): IHTTPResponse;
var
  AStream: TStringStream;
  AHttp: THTTPClient;
begin
  AHttp := CreateHttp;
  AStream := TStringStream.Create(AData);
  try
    AStream.Position := 0;
    if ALinkedAccount <> '' then
      AHttp.CustomHeaders['account'] := ALinkedAccount;

    Result := AHttp.Post(GetEndpoint+AResource, AStream);
  finally
    AStream.Free;
    AHttp.Free;
  end;
end;

function TRyft.PatchHttp(AResource, AData: string; const ALinkedAccount: string = ''): IHTTPResponse;
var
  AStream: TStringStream;
  AHttp: THTTPClient;
begin
  AHttp := CreateHttp;
  AStream := TStringStream.Create(AData);
  try
    AStream.Position := 0;
    if ALinkedAccount <> '' then
      AHttp.CustomHeaders['account'] := ALinkedAccount;
    Result := AHttp.Patch(GetEndpoint+AResource, AStream);
  finally
    AStream.Free;
    AHttp.Free;
  end;
end;

function TRyft.UpdatePaymentSession(APaymentID: string;
                                    const ALinkedAccount: string = '';
                                    const AAmount: integer = -1;
                                    const ACurrency: string = '';
                                    const ACustomerEmail: string = '';
                                    const APlatFormFee: integer = -1;
                                    const AMetaData: TStrings = nil): IRyftPaymentSession;
var
  AJson: TJSONObject;
  AData: string;
  ICount: integer;
begin
  Result := TRyftPaymentSession.Create;
  AJson := TJsonObject.Create;
  try
    if AAmount > -1 then AJson.S['amount'] := IntToStr(AAmount);
    if ACurrency <> '' then AJson.S['currency'] := ACurrency;
    if ACustomerEmail <> '' then AJson.S['customerEmail'] := ACustomerEmail;
    if APlatformFee > -1 then AJson.S['platformFee'] := IntToStr(APlatformFee);
    if AMetaData <> nil then
    begin
      for ICount := 0 to AMetaData.Count-1 do
      begin
        AJson.O['metadata'].S[AMetaData.Names[ICount]] := AMetaData.ValueFromIndex[ICount];
        if ICount = 4 then
          Break;
      end;
    end;
    AData := PatchHttp('payment-sessions/'+APaymentID, AJson.ToJSON, ALinkedAccount).ContentAsString;
    Result.LoadFromJson(AData);
  finally
    AJson.Free;
  end;
end;

{ TRyftPaymentSession }

constructor TRyftPaymentSession.Create;
begin
  FMetaData := TList<TMetaDataItem>.Create;
end;

destructor TRyftPaymentSession.Destroy;
begin
  FMetaData.Free;
  inherited;
end;

function TRyftPaymentSession.GetAmount: integer;
begin
  Result := FAmount;
end;

function TRyftPaymentSession.GetClientSecret: string;
begin
  Result := FClientSecret;
end;

function TRyftPaymentSession.GetCreatedTimeStamp: TDateTime;
begin
  Result := FCreatedTimeStamp;
end;

function TRyftPaymentSession.GetCurrency: string;
begin
  Result := FCurrency;
end;

function TRyftPaymentSession.GetCustomerEmail: string;
begin
  Result := FCustomerEmail;
end;

function TRyftPaymentSession.GetID: string;
begin
  Result := FID;
end;

function TRyftPaymentSession.GetLastError: string;
begin
  Result := FLastError;
end;

function TRyftPaymentSession.GetLastUpdatedTimeStamp: TDateTime;
begin
  Result := FLastUpdatedTimeStamp;
end;

function TRyftPaymentSession.GetMetaData: TList<TMetaDataItem>;
begin
  Result := FMetaData;
end;

function TRyftPaymentSession.GetPlatformFee: integer;
begin
  Result := FPlatformFee;
end;

function TRyftPaymentSession.GetRefundedAmount: integer;
begin
  Result := FRefundedAmount;
end;

function TRyftPaymentSession.GetRequiredAction: TRequiredAction;
begin
  Result := FRequiredAction;
end;

function TRyftPaymentSession.GetReturnURL: string;
begin
  Result := FReturnUrl;
end;

function TRyftPaymentSession.GetStatementDescriptor: TRyftStatementDescriptor;
begin
  Result := FStatementDescriptor;
end;

function TRyftPaymentSession.GetStatus: string;
begin
  Result := FStatus;
end;

procedure TRyftPaymentSession.LoadFromJson(AJsonData: string);
var
  AJson: TJsonObject;
begin
  AJson := TJsonObject.Parse(AJsonData) as TJsonObject;
  try
    FID := AJson.S['id'];
    FAmount := AJson.I['amount'];
    FCurrency := AJson.S['currency'];
    FStatementDescriptor.FDescriptor := AJson.O['statementDescriptor'].S['descriptor'];
    FStatementDescriptor.FCity := AJson.O['statementDescriptor'].S['city'];
    FRequiredAction.FType := AJson.O['requiredAction'].S['type'];
    FRequiredAction.FURL := AJson.O['requiredAction'].S['url'];
    FReturnUrl := AJson.S['returnUrl'];
    FCreatedTimeStamp := UnixToDateTime(AJson.I['createdTimestamp']);
    FLastUpdatedTimeStamp := UnixToDateTime(AJson.I['lastUpdatedTimestamp']);
  finally
    AJson.Free;
  end;
end;

end.
