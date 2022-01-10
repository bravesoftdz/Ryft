# Ryft
Pascal interfaces for Ryft

#### Example Usage

```delphi
procedure TfrmMain.Button1Click(Sender: TObject);
var
  ARyft: IRyft;
  APaymentSession: IRyftPaymentSession;
begin
  // create a Ryft interface
  ARyft := CreateRyft('sk_sandbox_**************', True);
  
  // create a PaymentSession object
  APaymentSession := ARyft.CreatePaymentSession(1000,
                                                'GBP',
                                                'graham@kernow-software.co.uk',
                                                0,
                                                '',
                                                False,
                                                nil,
                                                '',
                                                'https://www.kernow-software.co.uk');


  // retrieve a PaymentSession object
  APaymentSession := ARyft.GetPaymentSession(APaymentSession.ID);


  // update a PaymentSession object
  APaymentSession := ARyft.UpdatePaymentSession(APaymentSession.ID, '', 1500);

end;
```
