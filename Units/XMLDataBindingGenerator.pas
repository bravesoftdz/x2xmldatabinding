unit XMLDataBindingGenerator;

// #ToDo2 (MvR) 25-4-2008: typed wrapper for NodeValue if needed (eg. element with attributes and a value)

interface
uses
  Classes,
  Contnrs,
  XMLSchema;

type
  TXMLDataBindingSchema = class;
  TXMLDataBindingGeneratorItem = class;
  TXMLDataBindingItem = class;
  TXMLDataBindingInterface = class;
  TXMLDataBindingEnumerationMember = class;
  TXMLDataBindingEnumeration = class;
  TXMLDataBindingProperty = class;
  TXMLDataBindingItemProperty = class;
  TXMLDataBindingUnresolvedItem = class;


  TXMLDataBindingOutputType = (otSingle, otMultiple);
  TXMLDataBindingItemType = (itInterface, itEnumeration, itEnumerationMember,
                             itProperty, itUnresolved,
                             itComplexTypeAlias, itSimpleTypeAlias);
  TXMLDataBindingInterfaceType = (ifElement, ifComplexType, ifEnumeration);
  TXMLDataBindingPropertyType = (ptSimple, ptItem);
  TXMLDataBindingOccurance = (boMinOccurs, boMaxOccurs);


  TXMLDataBindingIterateItemsProc = procedure(AItem: TXMLDataBindingItem; AData: Pointer; var AAbort: Boolean) of object;
  TXMLDataBindingPostProcessItemEvent = procedure(Sender: TObject; Item: TXMLDataBindingItem) of object;


  TXMLDataBindingGenerator = class(TObject)
  private
    FIncludePaths:      TStrings;
    FOutputPath:        String;
    FOutputType:        TXMLDataBindingOutputType;
    FSourceFileName:    String;

    FSchemas:           TObjectList;

    FOnPostProcessItem: TXMLDataBindingPostProcessItemEvent;

    function GetSchemaCount: Integer;
    function GetSchemas(Index: Integer): TXMLDataBindingSchema;
  protected
    function LoadSchema(const AStream: TStream; const ASchemaName: String): TXMLDataBindingSchema;
    function GetSchemaData(const ALocation: String; out ASourceFileName: String): TStream;
    function FindSchema(const ALocation: String): TXMLDataBindingSchema;

    procedure GenerateSchemaObjects(ASchema: TXMLDataBindingSchema; ARootDocument: Boolean);
    procedure GenerateElementObjects(ASchema: TXMLDataBindingSchema; ARootDocument: Boolean);
    procedure GenerateComplexTypeObjects(ASchema: TXMLDataBindingSchema);
    procedure GenerateSimpleTypeObjects(ASchema: TXMLDataBindingSchema);

    function CheckElementOccurance(AElement: IXMLElementDef; AOccurance: TXMLDataBindingOccurance): Boolean;
    function IsElementOptional(AElement: IXMLElementDef): Boolean;
    function IsElementRepeating(AElement: IXMLElementDef): Boolean;
    function IsChoice(AElement: IXMLElementDef): Boolean;

    function ProcessElement(ASchema: TXMLDataBindingSchema; AElement: IXMLElementDef): TXMLDataBindingItem; overload;
    function ProcessElement(ASchema: TXMLDataBindingSchema; AAttribute: IXMLAttributeDef): TXMLDataBindingItem; overload;
    procedure ProcessChildElement(ASchema: TXMLDataBindingSchema; AElement: IXMLElementDef; AInterface: TXMLDataBindingInterface);
    procedure ProcessAttribute(ASchema: TXMLDataBindingSchema; AAttribute: IXMLAttributeDef; AInterface: TXMLDataBindingInterface);

    function IterateSchemaItems(ASchema: TXMLDataBindingSchema; AIterateProc: TXMLDataBindingIterateItemsProc; AData: Pointer): TXMLDataBindingItem;

    procedure FindInterfaceProc(AItem: TXMLDataBindingItem; AData: Pointer; var AAbort: Boolean);
    function FindInterface(ASchema: TXMLDataBindingSchema; const AName: String; AType: TXMLDataBindingInterfaceType): TXMLDataBindingInterface;

    procedure FindEnumerationProc(AItem: TXMLDataBindingItem; AData: Pointer; var AAbort: Boolean);
    function FindEnumeration(ASchema: TXMLDataBindingSchema; const AName: String; AAttribute: Boolean): TXMLDataBindingEnumeration;

    procedure ReplaceItem(const AOldItem, ANewItem: TXMLDataBindingItem);

    procedure ResolveSchema(ASchema: TXMLDataBindingSchema);
    procedure ResolveAlias(ASchema: TXMLDataBindingSchema);
    procedure ResolveItem(ASchema: TXMLDataBindingSchema; AItem: TXMLDataBindingUnresolvedItem);
    procedure ResolveNameConflicts;


    procedure PostProcessSchema(ASchema: TXMLDataBindingSchema);
    procedure PostProcessItem(ASchema: TXMLDataBindingSchema; AItem: TXMLDataBindingItem);
    function TranslateItemName(AItem: TXMLDataBindingItem): String; virtual;

    procedure GenerateDataBinding; virtual; abstract;

    property SourceFileName:            String                read FSourceFileName  write FSourceFileName;
    property SchemaCount:               Integer               read GetSchemaCount;
    property Schemas[Index: Integer]:   TXMLDataBindingSchema read GetSchemas;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Execute(const AStream: TStream; const ASchemaName: String); overload;
    procedure Execute(const AFileName: String); overload;

    property IncludePaths:    TStrings                  read FIncludePaths;
    property OutputType:      TXMLDataBindingOutputType read FOutputType      write FOutputType;
    property OutputPath:      String                    read FOutputPath      write FOutputPath;

    property OnPostProcessItem: TXMLDataBindingPostProcessItemEvent read FOnPostProcessItem write FOnPostProcessItem;
  end;


  TXMLDataBindingGeneratorItem = class(TObject)
  private
    FOwner:   TXMLDataBindingGenerator;
  protected
    procedure ReplaceItem(const AOldItem, ANewItem: TXMLDataBindingItem); virtual;

    property Owner: TXMLDataBindingGenerator  read FOwner;
  public
    constructor Create(AOwner: TXMLDataBindingGenerator);
  end;


  TXMLDataBindingSchema = class(TXMLDataBindingGeneratorItem)
  private
    FIncludes:            TObjectList;
    FItems:               TObjectList;
    FItemsGenerated:      Boolean;
    FSchemaDef:           IXMLSchemaDef;
    FSchemaName:          String;
    FSourceFileName:      String;

    function GetItemCount: Integer;
    function GetItems(Index: Integer): TXMLDataBindingItem;
    function GetIncludeCount: Integer;
    function GetIncludes(Index: Integer): TXMLDataBindingSchema;
    function GetTargetNamespace: String;
  protected
    procedure ReplaceItem(const AOldItem, ANewItem: TXMLDataBindingItem); override;

    procedure AddInclude(ASchema: TXMLDataBindingSchema);
    procedure AddItem(AItem: TXMLDataBindingItem);
    procedure InsertItem(AItem, AAfter: TXMLDataBindingItem);

    property ItemsGenerated:  Boolean read FItemsGenerated  write FItemsGenerated;
  public
    constructor Create(AOwner: TXMLDataBindingGenerator);
    destructor Destroy; override;

    property TargetNamespace:           String                read GetTargetNamespace;

    property IncludeCount:              Integer               read GetIncludeCount;
    property Includes[Index: Integer]:  TXMLDataBindingSchema read GetIncludes;

    property SchemaDef:                 IXMLSchemaDef         read FSchemaDef       write FSchemaDef;
    property SchemaName:                String                read FSchemaName      write FSchemaName;
    property SourceFileName:            String                read FSourceFileName  write FSourceFileName;

    property ItemCount:                 Integer               read GetItemCount;
    property Items[Index: Integer]:     TXMLDataBindingItem   read GetItems;
  end;


  TXMLDataBindingItem = class(TXMLDataBindingGeneratorItem)
  private
    FCollectionItem:  TXMLDataBindingProperty;
    FDocumentElement: Boolean;
    FName:            String;
    FSchema:          TXMLDataBindingSchema;
    FSchemaItem:      IXMLSchemaItem;
    FTranslatedName:  String;

    function GetDocumentation: String;
    function GetHasDocumentation: Boolean;
    function GetIsCollection: Boolean;
  protected
    function GetItemType: TXMLDataBindingItemType; virtual; abstract;
    procedure SetName(const Value: String);

    property SchemaItem:      IXMLSchemaItem            read FSchemaItem;
  public
    constructor Create(AOwner: TXMLDataBindingGenerator; ASchemaItem: IXMLSchemaItem; const AName: String);

    property Schema:              TXMLDataBindingSchema     read FSchema          write FSchema;

    property DocumentElement:     Boolean                   read FDocumentElement write FDocumentElement;
    property Documentation:       String                    read GetDocumentation;
    property HasDocumentation:    Boolean                   read GetHasDocumentation;
    property ItemType:            TXMLDataBindingItemType   read GetItemType;
    property Name:                String                    read FName;
    property TranslatedName:      String                    read FTranslatedName  write FTranslatedName;

    property CollectionItem:      TXMLDataBindingProperty   read FCollectionItem  write FCollectionItem;
    property IsCollection:        Boolean                   read GetIsCollection;
  end;


  TXMLDataBindingInterface = class(TXMLDataBindingItem)
  private
    FInterfaceType:   TXMLDataBindingInterfaceType;
    FIsSequence:      Boolean;
    FProperties:      TObjectList;
    FBaseName:        String;
    FBaseItem:        TXMLDataBindingInterface;

    function GetProperties(Index: Integer): TXMLDataBindingProperty;
    function GetPropertyCount: Integer;
    function GetCanValidate: Boolean;
  protected
    function GetItemType: TXMLDataBindingItemType; override;

    procedure ReplaceItem(const AOldItem: TXMLDataBindingItem; const ANewItem: TXMLDataBindingItem); override;

    procedure AddProperty(AProperty: TXMLDataBindingProperty);
  public
    constructor Create(AOwner: TXMLDataBindingGenerator; ASchemaItem: IXMLSchemaItem; const AName: String);
    destructor Destroy; override;

    property BaseName:        String                        read FBaseName        write FBaseName;
    property BaseItem:        TXMLDataBindingInterface      read FBaseItem        write FBaseItem;

    property CanValidate:     Boolean                       read GetCanValidate;
    property InterfaceType:   TXMLDataBindingInterfaceType  read FInterfaceType;
    property IsSequence:      Boolean                       read FIsSequence;

    property PropertyCount:               Integer                 read GetPropertyCount;
    property Properties[Index: Integer]:  TXMLDataBindingProperty read GetProperties;
  end;


  TXMLDataBindingEnumerationMember = class(TXMLDataBindingItem)
  private
    FEnumeration: TXMLDataBindingEnumeration;
  protected
    function GetItemType: TXMLDataBindingItemType; override;
  public
    constructor Create(AOwner: TXMLDataBindingGenerator; AEnumeration: TXMLDataBindingEnumeration; const AName: String);

    property Enumeration: TXMLDataBindingEnumeration  read FEnumeration;
  end;


  TXMLDataBindingEnumeration = class(TXMLDataBindingItem)
  private
    FMembers:       TObjectList;
    FIsAttribute:   Boolean;

    function GetMemberCount: Integer;
    function GetMembers(Index: Integer): TXMLDataBindingEnumerationMember;
  protected
    function GetItemType: TXMLDataBindingItemType; override;
  public
    constructor Create(AOwner: TXMLDataBindingGenerator; ASchemaItem: IXMLSchemaItem; AEnumerations: IXMLEnumerationCollection; const AName: String; AIsAttribute: Boolean);
    destructor Destroy; override;

    property MemberCount:             Integer                           read GetMemberCount;
    property Members[Index: Integer]: TXMLDataBindingEnumerationMember  read GetMembers;
    property IsAttribute:             Boolean                           read FIsAttribute;
  end;


  TXMLDataBindingProperty = class(TXMLDataBindingItem)
  private
    FIsAttribute:   Boolean;
    FIsOptional:    Boolean;
    FIsNillable:    Boolean;
    FIsRepeating:   Boolean;
    FIsNodeValue:   Boolean;
    FCollection:    TXMLDataBindingInterface;
  protected
    function GetIsReadOnly: Boolean; virtual; abstract;

    function GetItemType: TXMLDataBindingItemType; override;
    function GetPropertyType: TXMLDataBindingPropertyType; virtual; abstract;
  public
    property IsAttribute:   Boolean                     read FIsAttribute   write FIsAttribute;
    property IsOptional:    Boolean                     read FIsOptional    write FIsOptional;
    property IsNillable:    Boolean                     read FIsNillable    write FIsNillable;
    property IsReadOnly:    Boolean                     read GetIsReadOnly;
    property IsRepeating:   Boolean                     read FIsRepeating   write FIsRepeating;
    property IsNodeValue:   Boolean                     read FIsNodeValue   write FIsNodeValue;
    property PropertyType:  TXMLDataBindingPropertyType read GetPropertyType;

    property Collection:    TXMLDataBindingInterface    read FCollection    write FCollection;
  end;


  TXMLDataBindingSimpleProperty = class(TXMLDataBindingProperty)
  private
    FDataType:  IXMLTypeDef;
  protected
    function GetIsReadOnly: Boolean; override;
    function GetPropertyType: TXMLDataBindingPropertyType; override;
  public
    constructor Create(AOwner: TXMLDataBindingGenerator; ASchemaItem: IXMLSchemaItem; const AName: String; ADataType: IXMLTypeDef);
    constructor CreateFromAlias(AOwner: TXMLDataBindingGenerator; AProperty: TXMLDataBindingItemProperty; ADataType: IXMLTypeDef);

    property DataType:  IXMLTypeDef read FDataType;
  end;


  TXMLDataBindingItemProperty = class(TXMLDataBindingProperty)
  private
    FItem:  TXMLDataBindingItem;
  protected
    function GetIsReadOnly: Boolean; override;
    function GetPropertyType: TXMLDataBindingPropertyType; override;

    procedure ReplaceItem(const AOldItem, ANewItem: TXMLDataBindingItem); override;
  public
    constructor Create(AOwner: TXMLDataBindingGenerator; ASchemaItem: IXMLSchemaItem; const AName: String; AItem: TXMLDataBindingItem);

    property Item:  TXMLDataBindingItem read FItem;
  end;


  TXMLDataBindingUnresolvedItem = class(TXMLDataBindingItem)
  private
    FInterfaceType: TXMLDataBindingInterfaceType;
    FIsAttribute:   Boolean;
  protected
    function GetItemType: TXMLDataBindingItemType; override;
  public
    constructor Create(AOwner: TXMLDataBindingGenerator; ASchemaItem: IXMLSchemaItem; const AName: String; AInterfaceType: TXMLDataBindingInterfaceType; AIsAttribute: Boolean);

    property InterfaceType:   TXMLDataBindingInterfaceType  read FInterfaceType;
    property IsAttribute:     Boolean                       read FIsAttribute;
  end;


  TXMLDataBindingComplexTypeAliasItem = class(TXMLDataBindingItem)
  private
    FItem: TXMLDataBindingItem;
  protected
    function GetItemType: TXMLDataBindingItemType; override;

    procedure ReplaceItem(const AOldItem, ANewItem: TXMLDataBindingItem); override;
  public
    property Item:  TXMLDataBindingItem read FItem  write FItem;
  end;


  TXMLDataBindingSimpleTypeAliasItem = class(TXMLDataBindingItem)
  private
    FDataType:  IXMLTypeDef;
  protected
    function GetItemType: TXMLDataBindingItemType; override;
  public
    property DataType:  IXMLTypeDef read FDataType  write FDataType;
  end;
  

implementation
uses
  SysUtils,
  Variants,
  Windows,
  XMLDoc,
  XMLIntf,
  XMLSchemaTags,

  X2UtHashes;


const
  MaxOccursUnbounded  = 'unbounded';
  UseOptional         = 'optional';
  CollectionPostfix   = 'List';
  AttributeNillable   = 'nillable';


function GetInterfaceType(ASchemaItem: IXMLSchemaItem): TXMLDataBindingInterfaceType;
begin
  if Supports(ASchemaItem, IXMLComplexTypeDef) then
    Result  := ifComplexType
  else
    Result  := ifElement;
end;



{ TXMLDataBindingGenerator }
constructor TXMLDataBindingGenerator.Create;
begin
  inherited Create;

  FIncludePaths := TStringList.Create;
  FSchemas      := TObjectList.Create(True);

  with TStringList(FIncludePaths) do
  begin
    CaseSensitive := False;
    Duplicates    := dupIgnore;
  end;
end;


destructor TXMLDataBindingGenerator.Destroy;
begin
  FreeAndNil(FSchemas);
  FreeAndNil(FIncludePaths);

  inherited;
end;


procedure TXMLDataBindingGenerator.Execute(const AStream: TStream; const ASchemaName: String);
var
  schemaIndex:    Integer;
  schema:         TXMLDataBindingSchema;

begin
  FSchemas.Clear;
  schema  := LoadSchema(AStream, ASchemaName);
  if Assigned(schema) then
    schema.SourceFileName := SourceFileName;    

  if SchemaCount > 0 then
  begin
    { Map schema elements to objects }
    for schemaIndex := 0 to Pred(SchemaCount) do
      GenerateSchemaObjects(Schemas[schemaIndex], (schemaIndex = 0));


    { Process unresolved references }
    for schemaIndex := Pred(SchemaCount) downto 0 do
      ResolveSchema(Schemas[schemaIndex]);


    { After all lookups have been done, unwrap alias items }
    for schemaIndex := Pred(SchemaCount) downto 0 do
      ResolveAlias(Schemas[schemaIndex]);


    { Resolve naming conflicts }
    ResolveNameConflicts;


    { Perform final post-processing (translating names, generating collections) }
    for schemaIndex := 0 to Pred(SchemaCount) do
      PostProcessSchema(Schemas[schemaIndex]);


    { Output }
    GenerateDataBinding;
  end;
end;


procedure TXMLDataBindingGenerator.Execute(const AFileName: String);
var
  currentDir:   String;
  fileStream:   TFileStream;

begin
  currentDir  := GetCurrentDir;
  try
    ChDir(ExtractFilePath(AFileName));

    fileStream := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyNone);
    try
      FSourceFileName := AFileName;
      IncludePaths.Add(ExtractFilePath(AFileName));

      Execute(fileStream, ChangeFileExt(ExtractFileName(AFileName), ''));
    finally
      FreeAndNil(fileStream);
    end;
  finally
    ChDir(currentDir);
  end;
end;



function TXMLDataBindingGenerator.LoadSchema(const AStream: TStream; const ASchemaName: String): TXMLDataBindingSchema;

  procedure HandleDocRefs(const ADocRefs: IXMLSchemaDocRefs; ASchema: TXMLDataBindingSchema);
  var
    location:       String;
    schemaName:     String;
    refSchema:      TXMLDataBindingSchema;
    refIndex:       Integer;
    refStream:      TStream;
    sourceFileName: String;

  begin
    for refIndex := 0 to Pred(ADocRefs.Count) do
    begin
      location      := ADocRefs[refIndex].SchemaLocation;
      schemaName    := ChangeFileExt(ExtractFileName(location), '');
      refSchema     := FindSchema(schemaName);

      if not Assigned(refSchema) then
      begin
        refStream     := GetSchemaData(location, sourceFileName);

        if Assigned(refStream) then
        try
          refSchema   := LoadSchema(refStream, schemaName);

          if Assigned(refSchema) then
            refSchema.SourceFileName  := sourceFileName;
        finally
          FreeAndNil(refStream);
        end;
      end;

      if Assigned(refSchema) then
        ASchema.AddInclude(refSchema);
    end;
  end;


var
  schemaDoc:      IXMLSchemaDoc;
  schemaDef:      IXMLSchemaDef;

begin
  schemaDoc := TXMLSchemaDoc.Create(nil);
  schemaDoc.LoadFromStream(AStream);
  schemaDef := schemaDoc.SchemaDef;

  Result            := TXMLDataBindingSchema.Create(Self);
  Result.SchemaDef  := schemaDef;
  Result.SchemaName := ASchemaName;
  FSchemas.Add(Result);

  { Handle imports / includes }
  HandleDocRefs(schemaDef.SchemaImports, Result);
  HandleDocRefs(schemaDef.SchemaIncludes, Result);
end;


function TXMLDataBindingGenerator.GetSchemaData(const ALocation: String; out ASourceFileName: String): TStream;
var
  includeIndex:   Integer;
  includePath:    String;

begin
  Result := nil;

  for includeIndex := 0 to Pred(IncludePaths.Count) do
  begin
    includePath := IncludeTrailingPathDelimiter(IncludePaths[includeIndex]);

    if FileExists(includePath + ALocation) then
    begin
      ASourceFileName := includePath + ALocation;
      Result := TFileStream.Create(ASourceFileName, fmOpenRead or fmShareDenyNone);
      break;
    end;
  end;
end;


function TXMLDataBindingGenerator.FindSchema(const ALocation: String): TXMLDataBindingSchema;
var
  schemaIndex: Integer;

begin
  Result  := nil;

  for schemaIndex := 0 to Pred(SchemaCount) do
    if Schemas[schemaIndex].SchemaName = ALocation then
    begin
      Result  := Schemas[schemaIndex];
      break;
    end;
end;


procedure TXMLDataBindingGenerator.GenerateSchemaObjects(ASchema: TXMLDataBindingSchema; ARootDocument: Boolean);
var
  includeIndex:         Integer;

begin
  if ASchema.ItemsGenerated then
    exit;

  ASchema.ItemsGenerated  := True;

  { First generate the objects for all includes and imports, so we can get
    proper references. }
  for includeIndex := 0 to Pred(ASchema.IncludeCount) do
    GenerateSchemaObjects(ASchema.Includes[includeIndex], False);

  GenerateElementObjects(ASchema, ARootDocument);
  GenerateComplexTypeObjects(ASchema);
  GenerateSimpleTypeObjects(ASchema);
end;


procedure TXMLDataBindingGenerator.GenerateElementObjects(ASchema: TXMLDataBindingSchema; ARootDocument: Boolean);
var
  schemaDef: IXMLSchemaDef;
  elementIndex: Integer;
  item: TXMLDataBindingItem;
  attributeIndex: Integer;

begin
  schemaDef := ASchema.SchemaDef;

  for elementIndex := 0 to Pred(schemaDef.ElementDefs.Count) do
  begin
    item  := ProcessElement(ASchema, schemaDef.ElementDefs[elementIndex]);

    if Assigned(item) and ARootDocument then
      item.DocumentElement  := True;
  end;

  for attributeIndex := 0 to Pred(schemaDef.AttributeDefs.Count) do
    ProcessElement(ASchema, schemaDef.AttributeDefs[attributeIndex]);
end;


procedure TXMLDataBindingGenerator.GenerateComplexTypeObjects(ASchema: TXMLDataBindingSchema);
var
  schemaDef:            IXMLSchemaDef;
  complexTypeIndex:     Integer;
  complexType:          IXMLComplexTypeDef;
  interfaceItem:        TXMLDataBindingInterface;
  elementIndex:         Integer;
  attributeIndex:       Integer;

begin
  schemaDef := ASchema.SchemaDef;

  for complexTypeIndex := 0 to Pred(schemaDef.ComplexTypes.Count) do
  begin
    complexType   := schemaDef.ComplexTypes[complexTypeIndex];

    interfaceItem := TXMLDataBindingInterface.Create(Self, complexType, complexType.Name);

    if complexType.DerivationMethod <> dmNone then
      interfaceItem.BaseName := complexType.BaseTypeName;

    ASchema.AddItem(interfaceItem);

    for elementIndex := 0 to Pred(complexType.ElementDefList.Count) do
      ProcessChildElement(ASchema, complexType.ElementDefList[elementIndex], interfaceItem);

    for attributeIndex := 0 to Pred(complexType.AttributeDefs.Count) do
      ProcessAttribute(ASchema, complexType.AttributeDefs[attributeIndex], interfaceItem);
  end;
end;


procedure TXMLDataBindingGenerator.GenerateSimpleTypeObjects(ASchema: TXMLDataBindingSchema);
var
  schemaDef:            IXMLSchemaDef;
  simpleTypeIndex:      Integer;
  simpleType:           IXMLSimpleTypeDef;
  enumerationObject:    TXMLDataBindingEnumeration; 

begin
  schemaDef := ASchema.SchemaDef;

  for simpleTypeIndex := 0 to Pred(schemaDef.SimpleTypes.Count) do
  begin
    simpleType  := schemaDef.SimpleTypes[simpleTypeIndex];

    if simpleType.Enumerations.Count > 0 then
    begin
      enumerationObject := TXMLDataBindingEnumeration.Create(Self, simpleType, simpleType.Enumerations, simpleType.Name, False);
      ASchema.AddItem(enumerationObject);
    end;
  end;
end;


function TXMLDataBindingGenerator.CheckElementOccurance(AElement: IXMLElementDef; AOccurance: TXMLDataBindingOccurance): Boolean;

  function CheckParent(const ANode: IXMLNode): Boolean;
  var
    compositor:   IXMLElementCompositor;

  begin
    Result := False;

    if Supports(ANode, IXMLElementCompositor, compositor) then
    begin
      case AOccurance of
        boMinOccurs:  Result := (compositor.MinOccurs = 0);
        boMaxOccurs:  Result := (compositor.MaxOccurs = MaxOccursUnbounded) or
                                (compositor.MaxOccurs > 1);
      end;

      if not Result then
        Result := CheckParent(compositor.ParentNode);
    end;
  end;


begin
  Result := False;
  
  case AOccurance of
    boMinOccurs:  Result := (AElement.MinOccurs = 0);
    boMaxOccurs:  Result := (AElement.MaxOccurs = MaxOccursUnbounded) or
                            (AElement.MaxOccurs > 1);
  end;

  if not Result then
    Result := CheckParent(AElement.ParentNode);
end;


function TXMLDataBindingGenerator.IsElementOptional(AElement: IXMLElementDef): Boolean;
begin
  Result := CheckElementOccurance(AElement, boMinOccurs);
end;


function TXMLDataBindingGenerator.IsElementRepeating(AElement: IXMLElementDef): Boolean;
begin
  Result := CheckElementOccurance(AElement, boMaxOccurs);
end;


function TXMLDataBindingGenerator.IsChoice(AElement: IXMLElementDef): Boolean;
var
  compositor:   IXMLElementCompositor;

begin
  Result := False;

  if Supports(AElement.ParentNode, IXMLElementCompositor, compositor) then
    Result := (compositor.CompositorType = ctChoice) and
              (compositor.ElementDefs.Count > 1);
end;


function TXMLDataBindingGenerator.ProcessElement(ASchema: TXMLDataBindingSchema; AElement: IXMLElementDef): TXMLDataBindingItem;
var
  attributeIndex:       Integer;
  enumerationObject:    TXMLDataBindingEnumeration;
  interfaceObject:      TXMLDataBindingInterface;
  complexAliasItem:     TXMLDataBindingComplexTypeAliasItem;
  simpleAliasItem:      TXMLDataBindingSimpleTypeAliasItem;
  elementIndex:         Integer;
  simpleTypeDef:        IXMLSimpleTypeDef;
  typeDef: IXMLTypeDef;

begin
  Result := nil;
  interfaceObject := nil;

  if Assigned(AElement.Ref) then
  begin
    { Find reference. If not found, mark as "resolve later". }
    Result := FindInterface(ASchema, AElement.Ref.Name, ifElement);

    if not Assigned(Result) then
    begin
      Result  := TXMLDataBindingUnresolvedItem.Create(Self, AElement, AElement.Ref.Name, ifElement, False);
      ASchema.AddItem(Result);
    end;
  end else
  begin
    if not AElement.DataType.IsAnonymous then
    begin
      if AElement.DataType.IsComplex then
      begin
        { Find data type. If not found, mark as "resolve later". }
        Result  := FindInterface(ASchema, AElement.DataTypeName, ifComplexType);

        if not Assigned(Result) then
        begin
          Result  := TXMLDataBindingUnresolvedItem.Create(Self, AElement, AElement.DataTypeName, ifComplexType, True);
          ASchema.AddItem(Result);
        end;

        if AElement.IsGlobal then
        begin
          { The element is global, but only references a complex type. Keep track
            to properly resolve references to the element. }
          complexAliasItem      := TXMLDataBindingComplexTypeAliasItem.Create(Self, AElement, AElement.Name);
          complexAliasItem.Item := Result;
          ASchema.AddItem(complexAliasItem);
        end;
      end else if Supports(AElement.DataType, IXMLSimpleTypeDef, simpleTypeDef) then
      begin
        if simpleTypeDef.Enumerations.Count > 0 then
        begin
          { References enumeration. }
          Result  := FindEnumeration(ASchema, AElement.DataTypeName, False);

          if not Assigned(Result) then
          begin
            Result  := TXMLDataBindingUnresolvedItem.Create(Self, AElement, AElement.DataTypeName, ifEnumeration, False);
            ASchema.AddItem(Result);
          end;
        end else if simpleTypeDef.IsBuiltInType and AElement.IsGlobal then
        begin
          { The element is global, but only references a simple type. }
          simpleAliasItem           := TXMLDataBindingSimpleTypeAliasItem.Create(Self, AElement, AElement.Name);
          simpleAliasItem.DataType  := AElement.DataType;
          ASchema.AddItem(simpleAliasItem);

          Result  := simpleAliasItem;
        end;
      end;
    end;

    if not Assigned(Result) then
    begin
      if AElement.DataType.Enumerations.Count > 0 then
      begin
        { Enumeration }
        enumerationObject := TXMLDataBindingEnumeration.Create(Self, AElement, AElement.DataType.Enumerations, AElement.Name, False);
        ASchema.AddItem(enumerationObject);
        Result := enumerationObject;
      end else if AElement.DataType.IsComplex then
      begin
        { Interface }
        interfaceObject := TXMLDataBindingInterface.Create(Self, AElement, AElement.Name);
        if Assigned(AElement.DataType.BaseType) then
          interfaceObject.BaseName := AElement.DataType.BaseTypeName;

        ASchema.AddItem(interfaceObject);
        Result := interfaceObject;
      end;

      if Assigned(interfaceObject) then
      begin
        for elementIndex := 0 to Pred(AElement.ChildElements.Count) do
          ProcessChildElement(ASchema, AElement.ChildElements[elementIndex], interfaceObject);

        for attributeIndex := 0 to Pred(AElement.AttributeDefs.Count) do
          ProcessAttribute(ASchema, AElement.AttributeDefs[attributeIndex], interfaceObject);
      end else if AElement.IsGlobal then
      begin
        { Non-anonymous non-complex type. Assume somewhere in there is a
          built-in type.

          This code probably isn't correct, but it works for the files I got. }
        typeDef := AElement.DataType;

        while Assigned(typeDef) do
        begin
          if Supports(typeDef, IXMLSimpleTypeDef, simpleTypeDef) and (simpleTypeDef.IsBuiltInType) then
          begin
            { The element is global, but only references a simple type. }
            simpleAliasItem           := TXMLDataBindingSimpleTypeAliasItem.Create(Self, AElement, AElement.Name);
            simpleAliasItem.DataType  := typeDef;
            ASchema.AddItem(simpleAliasItem);

            Result  := simpleAliasItem;
            Break;
          end;

          typeDef := typeDef.BaseType;
        end;
      end;
    end;
  end;
end;


function TXMLDataBindingGenerator.ProcessElement(ASchema: TXMLDataBindingSchema; AAttribute: IXMLAttributeDef): TXMLDataBindingItem;
var
  enumerationObject: TXMLDataBindingEnumeration;
  interfaceObject: TXMLDataBindingInterface;
  complexAliasItem: TXMLDataBindingComplexTypeAliasItem;
  simpleAliasItem: TXMLDataBindingSimpleTypeAliasItem;
  simpleTypeDef: IXMLSimpleTypeDef;
  typeDef: IXMLTypeDef;

begin
  Result := nil;

  if Assigned(AAttribute.Ref) then
  begin
    { Find reference. If not found, mark as "resolve later". }
    Result := FindInterface(ASchema, AAttribute.Ref.Name, ifElement);

    if not Assigned(Result) then
    begin
      Result  := TXMLDataBindingUnresolvedItem.Create(Self, AAttribute, AAttribute.Ref.Name, ifElement, True);
      ASchema.AddItem(Result);
    end;
  end else
  begin
    if not AAttribute.DataType.IsAnonymous then
    begin
      if AAttribute.DataType.IsComplex then
      begin
        { Find data type. If not found, mark as "resolve later". }
        Result  := FindInterface(ASchema, AAttribute.DataTypeName, ifComplexType);

        if not Assigned(Result) then
        begin
          Result  := TXMLDataBindingUnresolvedItem.Create(Self, AAttribute, AAttribute.DataTypeName, ifComplexType, True);
          ASchema.AddItem(Result);
        end;

        if AAttribute.IsGlobal then
        begin
          { The element is global, but only references a complex type. Keep track
            to properly resolve references to the element. }
          complexAliasItem      := TXMLDataBindingComplexTypeAliasItem.Create(Self, AAttribute, AAttribute.Name);
          complexAliasItem.Item := Result;
          ASchema.AddItem(complexAliasItem);
        end;
      end else if Supports(AAttribute.DataType, IXMLSimpleTypeDef, simpleTypeDef) then
      begin
        if simpleTypeDef.Enumerations.Count > 0 then
        begin
          { References enumeration. }
          Result  := FindEnumeration(ASchema, AAttribute.DataTypeName, True);

          if not Assigned(Result) then
          begin
            Result  := TXMLDataBindingUnresolvedItem.Create(Self, AAttribute, AAttribute.DataTypeName, ifEnumeration, True);
            ASchema.AddItem(Result);
          end;
        end else if simpleTypeDef.IsBuiltInType and AAttribute.IsGlobal then
        begin
          { The element is global, but only references a simple type. }
          simpleAliasItem           := TXMLDataBindingSimpleTypeAliasItem.Create(Self, AAttribute, AAttribute.Name);
          simpleAliasItem.DataType  := AAttribute.DataType;
          ASchema.AddItem(simpleAliasItem);

          Result  := simpleAliasItem;
        end;
      end;
    end;

    if not Assigned(Result) then
    begin
      if AAttribute.DataType.Enumerations.Count > 0 then
      begin
        { Enumeration }
        enumerationObject := TXMLDataBindingEnumeration.Create(Self, AAttribute, AAttribute.DataType.Enumerations, AAttribute.Name, True);
        ASchema.AddItem(enumerationObject);
        Result := enumerationObject;
      end else if AAttribute.DataType.IsComplex then
      begin
        { Interface }
        interfaceObject := TXMLDataBindingInterface.Create(Self, AAttribute, AAttribute.Name);
        if Assigned(AAttribute.DataType.BaseType) then
          interfaceObject.BaseName := AAttribute.DataType.BaseTypeName;

        ASchema.AddItem(interfaceObject);
        Result := interfaceObject;
      end else if AAttribute.IsGlobal then
      begin
        { Non-anonymous non-complex type. Assume somewhere in there is a
          built-in type.

          This code probably isn't correct, but it works for the files I got. }
        typeDef := AAttribute.DataType;

        while Assigned(typeDef) do
        begin
          if Supports(typeDef, IXMLSimpleTypeDef, simpleTypeDef) and (simpleTypeDef.IsBuiltInType) then
          begin
            { The element is global, but only references a simple type. }
            simpleAliasItem           := TXMLDataBindingSimpleTypeAliasItem.Create(Self, AAttribute, AAttribute.Name);
            simpleAliasItem.DataType  := typeDef;
            ASchema.AddItem(simpleAliasItem);

            Result  := simpleAliasItem;
            Break;
          end;

          typeDef := typeDef.BaseType;
        end;
      end;
    end;
  end;
end;


procedure TXMLDataBindingGenerator.ProcessChildElement(ASchema: TXMLDataBindingSchema; AElement: IXMLElementDef; AInterface: TXMLDataBindingInterface);
var
  actualElement:        IXMLElementDef;
  propertyType:         TXMLDataBindingItem;
  propertyItem:         TXMLDataBindingProperty;

begin
  propertyType      := ProcessElement(ASchema, AElement);

  if Assigned(AInterface) then
  begin
    if Assigned(propertyType) then
      propertyItem  := TXMLDataBindingItemProperty.Create(Self, AElement,
                                                          AElement.Name,
                                                          propertyType)
    else
      propertyItem  := TXMLDataBindingSimpleProperty.Create(Self, AElement,
                                                            AElement.Name,
                                                            AElement.DataType);

    propertyItem.IsOptional   := IsElementOptional(AElement) or
                                 IsChoice(AElement);
    propertyItem.IsRepeating  := IsElementRepeating(AElement);


    actualElement := AElement;
    while Assigned(actualElement) and Assigned(actualElement.Ref) do
      actualElement := actualElement.Ref;

    if AElement.HasAttribute(AttributeNillable) then
      propertyItem.IsNillable := StrToBoolDef(AElement.Attributes[AttributeNillable], False)
    else if actualElement.HasAttribute(AttributeNillable) then
      propertyItem.IsNillable := StrToBoolDef(actualElement.Attributes[AttributeNillable], False);

    AInterface.AddProperty(propertyItem);
  end;
end;


procedure TXMLDataBindingGenerator.ProcessAttribute(ASchema: TXMLDataBindingSchema; AAttribute: IXMLAttributeDef; AInterface: TXMLDataBindingInterface);
var
  propertyItem:   TXMLDataBindingProperty;
  propertyType:   TXMLDataBindingItem;

begin
  propertyType  := ProcessElement(ASchema, AAttribute);

  if Assigned(propertyType) then
    propertyItem  := TXMLDataBindingItemProperty.Create(Self, AAttribute,
                                                        AAttribute.Name,
                                                        propertyType)
  else
    propertyItem  := TXMLDataBindingSimpleProperty.Create(Self, AAttribute,
                                                          AAttribute.Name,
                                                          AAttribute.DataType);

  propertyItem.IsOptional   := (AAttribute.Use = UseOptional);
  propertyItem.IsAttribute  := True;
  
  AInterface.AddProperty(propertyItem);
end;


function TXMLDataBindingGenerator.IterateSchemaItems(ASchema: TXMLDataBindingSchema; AIterateProc: TXMLDataBindingIterateItemsProc; AData: Pointer): TXMLDataBindingItem;
var
  abort:          Boolean;
  itemIndex:      Integer;
  schemaItem:     TXMLDataBindingItem;
  includeIndex:   Integer;

begin
  Result  := nil;
  abort   := False;

  for itemIndex := 0 to Pred(ASchema.ItemCount) do
  begin
    schemaItem  := ASchema.Items[itemIndex];

    AIterateProc(schemaItem, AData, abort);
    if abort then
    begin
      Result := schemaItem;
      Break;
    end;
  end;

  if not Assigned(Result) then
  begin
    for includeIndex := 0 to Pred(ASchema.IncludeCount) do
    begin
      Result  := IterateSchemaItems(ASchema.Includes[includeIndex], AIterateProc, AData);
      if Assigned(Result) then
        break;
    end;
  end;
end;



type
  PFindInterfaceInfo  = ^TFindInterfaceInfo;
  TFindInterfaceInfo  = record
    InterfaceType:    TXMLDataBindingInterfaceType;
    Name:             String;
  end;

  PFindEnumerationInfo  = ^TFindEnumerationInfo;
  TFindEnumerationInfo  = record
    Attribute:        Boolean;
    Name:             String;
  end;


procedure TXMLDataBindingGenerator.FindInterfaceProc(AItem: TXMLDataBindingItem; AData: Pointer; var AAbort: Boolean);
var
  findInfo:       PFindInterfaceInfo;

begin
  AAbort    := False;
  findInfo  := PFindInterfaceInfo(AData);


  if AItem.Name = findInfo^.Name then
  begin
    case AItem.ItemType of
      itInterface:
        AAbort  := (TXMLDataBindingInterface(AItem).InterfaceType = findInfo^.InterfaceType);

      itComplexTypeAlias,
      itSimpleTypeAlias:
        AAbort  := (findInfo^.InterfaceType = ifElement);
    end;
  end;
end;


function TXMLDataBindingGenerator.FindInterface(ASchema: TXMLDataBindingSchema; const AName: String; AType: TXMLDataBindingInterfaceType): TXMLDataBindingInterface;
var
  findInfo:   TFindInterfaceInfo;

begin
  findInfo.InterfaceType  := AType;
  findInfo.Name           := AName;
  Result                  := TXMLDataBindingInterface(IterateSchemaItems(ASchema, FindInterfaceProc, @findInfo));
end;


procedure TXMLDataBindingGenerator.FindEnumerationProc(AItem: TXMLDataBindingItem; AData: Pointer; var AAbort: Boolean);
var
  findInfo: PFindEnumerationInfo;

begin
  findInfo  := PFindEnumerationInfo(AData);
  AAbort    := (AItem.ItemType = itEnumeration) and
               (AItem.Name = findInfo^.Name) and
               (TXMLDataBindingEnumeration(AItem).IsAttribute = findInfo^.Attribute);
end;


function TXMLDataBindingGenerator.FindEnumeration(ASchema: TXMLDataBindingSchema; const AName: String; AAttribute: Boolean): TXMLDataBindingEnumeration;
var
  findInfo:   TFindEnumerationInfo;

begin
  findInfo.Attribute  := AAttribute;
  findInfo.Name       := AName;
  Result              := TXMLDataBindingEnumeration(IterateSchemaItems(ASchema, FindEnumerationProc, @findInfo));
end;


procedure TXMLDataBindingGenerator.ReplaceItem(const AOldItem, ANewItem: TXMLDataBindingItem);
var
  schemaIndex:  Integer;

begin
  for schemaIndex := Pred(SchemaCount) downto 0 do
    Schemas[schemaIndex].ReplaceItem(AOldItem, ANewItem);
end;


procedure TXMLDataBindingGenerator.ResolveSchema(ASchema: TXMLDataBindingSchema);
var
  itemIndex:      Integer;
  item:           TXMLDataBindingItem;
  interfaceItem:  TXMLDataBindingInterface;

begin
  for itemIndex := Pred(ASchema.ItemCount) downto 0 do
  begin
    item  := ASchema.Items[itemIndex];

    case item.ItemType of
      itInterface:
        begin
          { Resolve base interface }
          interfaceItem := TXMLDataBindingInterface(item);

          if (not Assigned(interfaceItem.BaseItem)) and
             (Length(interfaceItem.BaseName) > 0) then
            interfaceItem.BaseItem  := FindInterface(ASchema, interfaceItem.BaseName, ifComplexType);
        end;

      itUnresolved:
        ResolveItem(ASchema, TXMLDataBindingUnresolvedItem(item));
    end;
  end;
end;


procedure TXMLDataBindingGenerator.ResolveAlias(ASchema: TXMLDataBindingSchema);
var
  itemIndex:          Integer;
  item:               TXMLDataBindingItem;
  complexAliasItem:   TXMLDataBindingComplexTypeAliasItem;
  simpleAliasItem:    TXMLDataBindingSimpleTypeAliasItem;
  interfaceItem:      TXMLDataBindingInterface;

begin
  for itemIndex := Pred(ASchema.ItemCount) downto 0 do
  begin
    item  := ASchema.Items[itemIndex];

    case item.ItemType of
      itComplexTypeAlias:
        begin
          { Replace alias element with the actual complex type }
          complexAliasItem  := TXMLDataBindingComplexTypeAliasItem(item);
          if Assigned(complexAliasItem.Item) then
          begin
            // (MvR) 27-8-2008: instead, we allow the generation of an alias in
            //                  code, so it can be used as a document element
            // ReplaceItem(complexAliasItem, complexAliasItem.Item);

            interfaceItem           := TXMLDataBindingInterface.Create(Self, complexAliasItem.SchemaItem, complexAliasItem.Name);
            interfaceItem.BaseItem  := (complexAliasItem.Item as TXMLDataBindingInterface);
            interfaceItem.BaseName  := complexAliasItem.Item.Name;
            ASchema.AddItem(interfaceItem);

            ReplaceItem(complexAliasItem, interfaceItem);
            FreeAndNil(complexAliasItem);
          end;
        end;

      itSimpleTypeAlias:
        begin
          { Remove the alias element - TXMLDataBindingInterfaceItem.ReplaceItem
            will take care of fixing it's properties. }
          simpleAliasItem := TXMLDataBindingSimpleTypeAliasItem(item);
          ReplaceItem(simpleAliasItem, nil);
          FreeAndNil(simpleAliasItem);
        end;
    end;
  end;
end;


procedure TXMLDataBindingGenerator.ResolveItem(ASchema: TXMLDataBindingSchema; AItem: TXMLDataBindingUnresolvedItem);
var
  referenceItem:  TXMLDataBindingItem;

begin
  if not Assigned(AItem) then
    Exit;

  if AItem.InterfaceType = ifEnumeration then
    referenceItem := FindEnumeration(ASchema, AItem.Name, AItem.IsAttribute)
  else
  begin
    referenceItem := FindInterface(ASchema, AItem.Name, AItem.InterfaceType);

    if (not Assigned(referenceItem)) and
       (AItem.InterfaceType = ifElement) then
      referenceItem := FindEnumeration(ASchema, AItem.Name, AItem.IsAttribute);
  end;

  if Assigned(referenceItem) then
    ReplaceItem(AItem, referenceItem);
end;


procedure TXMLDataBindingGenerator.ResolveNameConflicts;
var
  itemNames:      TX2SOHash;


  procedure AddItem(AItem: TXMLDataBindingItem);
  var
    hashName:       String;
    items:          TObjectList;

  begin
    hashName  := AItem.Name;
    
    if not itemNames.Exists(hashName) then
    begin
      items               := TObjectList.Create(False);
      itemNames[hashName] := items;
    end else
      items               := TObjectList(itemNames[hashName]);

    items.Add(AItem);
  end;


  function ResolveItemNameConflict(AItem: TXMLDataBindingItem; ADepth: Integer; out ANewName: String): Boolean;
  var
    currentDepth:   Integer;
    parentNode:     IXMLNode;
    schemaItem:     IXMLSchemaItem;

  begin
    Result        := False;
    currentDepth  := 0;
    parentNode    := AItem.SchemaItem;
    ANewName      := AItem.Name;

    while Assigned(parentNode) do
    begin
      parentNode  := parentNode.ParentNode;

      if Assigned(parentNode) and
         Supports(parentNode, IXMLSchemaItem, schemaItem) and
         (Length(schemaItem.Name) > 0) then
      begin
        ANewName  := schemaItem.Name + ANewName;

        Inc(currentDepth);
        if currentDepth = ADepth then
        begin
          Result  := True;
          break;
        end;
      end;
    end;
  end;


var
  schemaIndex:    Integer;
  schema:         TXMLDataBindingSchema;
  itemIndex:      Integer;
  items:          TObjectList;
  item:           TXMLDataBindingItem;
  depth:          Integer;
  newName:        String;
  resolved:       Boolean;

begin
  itemNames := TX2SOHash.Create(True);
  try
    { Gather names }
    for schemaIndex := 0 to Pred(SchemaCount) do
    begin
      schema  := Schemas[schemaIndex];

      for itemIndex := 0 to Pred(schema.ItemCount) do
      begin
        item      := schema.Items[itemIndex];

        if item.ItemType in [itInterface, itEnumeration] then
          AddItem(item);
      end;
    end;


    { Find conflicts }
    itemNames.First;

    while itemNames.Next do
    begin
      items := TObjectList(itemNames.CurrentValue);

      if items.Count > 1 then
      begin
        { Attempt to rename items }
        for itemIndex := Pred(items.Count) downto 0 do
        begin
          item      := TXMLDataBindingItem(items[itemIndex]);
          newName   := item.Name;
          resolved  := False;
          depth     := 1;

          while ResolveItemNameConflict(item, depth, newName) do
          begin
            if not itemNames.Exists(newName) then
            begin
              resolved  := True;
              break;
            end else
              Inc(depth);
          end;

          { test }
          if not resolved then
          begin
            newName := newName + IntToStr(Succ(itemIndex));
            resolved := True;
          end;

          if resolved then
          begin
            items.Delete(itemIndex);

            item.SetName(newName);
            AddItem(item);
          end;
        end;
      end;
    end;
  finally
    FreeAndNil(itemNames);
  end;
end;


procedure TXMLDataBindingGenerator.PostProcessSchema(ASchema: TXMLDataBindingSchema);
var
  itemIndex:  Integer;

begin
  for itemIndex := Pred(ASchema.ItemCount) downto 0 do
    PostProcessItem(ASchema, ASchema.Items[itemIndex]);
end;


procedure TXMLDataBindingGenerator.PostProcessItem(ASchema: TXMLDataBindingSchema; AItem: TXMLDataBindingItem);
var
  collectionItem:       TXMLDataBindingInterface;
  collectionName:       string;
  enumerationItem:      TXMLDataBindingEnumeration;
  interfaceItem:        TXMLDataBindingInterface;
  memberIndex:          Integer;
  propertyIndex:        Integer;
  propertyItem:         TXMLDataBindingProperty;
  repeatingItems:       TObjectList;
  typedSchemaItem:      IXMLTypedSchemaItem;

begin
  { Translate name }
  AItem.TranslatedName := TranslateItemName(AItem);

  { Process members }
  case AItem.ItemType of
    itInterface:
      begin
        interfaceItem := TXMLDataBindingInterface(AItem);

        if (not Assigned(interfaceItem.BaseItem)) and
           (Length(interfaceItem.BaseName) > 0) then
        begin
          { Assume this is a reference to a simple type }
          if Supports(interfaceItem.SchemaItem, IXMLTypedSchemaItem, typedSchemaItem) then
          begin
            propertyItem := TXMLDataBindingSimpleProperty.Create(Self, interfaceItem.SchemaItem, 'Value',
                                                                 typedSchemaItem.DataType.BaseType);
            propertyItem.IsNodeValue := True;

            interfaceItem.AddProperty(propertyItem);
          end;
        end;


        for propertyIndex := 0 to Pred(interfaceItem.PropertyCount) do
          PostProcessItem(ASchema, interfaceItem.Properties[propertyIndex]);
      end;
    itEnumeration:
      begin
        enumerationItem := TXMLDataBindingEnumeration(AItem);

        for memberIndex := 0 to Pred(enumerationItem.MemberCount) do
          PostProcessItem(ASchema, enumerationItem.Members[memberIndex]);
      end;
  end;


  { Extract collections }
  if AItem.ItemType = itInterface then
  begin
    interfaceItem                 := TXMLDataBindingInterface(AItem);
    interfaceItem.CollectionItem  := nil;

    repeatingItems  := TObjectList.Create(False);
    try
      for propertyIndex := 0 to Pred(interfaceItem.PropertyCount) do
        if interfaceItem.Properties[propertyIndex].IsRepeating then
          repeatingItems.Add(interfaceItem.Properties[propertyIndex]);

      if repeatingItems.Count > 0 then
      begin
        if (repeatingItems.Count = 1) and
           (not Assigned(interfaceItem.BaseItem)) then
        begin
          { Single repeating child, the item itself is a collection parent }
          interfaceItem.CollectionItem  := TXMLDataBindingProperty(repeatingItems[0]);
        end else
        begin
          { Multiple repeating children or this interface is a descendant,
            create intermediate collections for each }
          for propertyIndex := 0 to Pred(repeatingItems.Count) do
          begin
            propertyItem  := TXMLDataBindingProperty(repeatingItems[propertyIndex]);

            // #ToDo1 (MvR) 7-4-2008: check if an item with the "List" postfix
            //                        exists in the schema, as it could cause
            //                        conflicts.
            // #ToDo1 (MvR) 30-7-2008: temporary implementation; have to check
            //                         for proper functioning later.
            collectionItem := FindInterface(ASchema, propertyItem.TranslatedName + CollectionPostfix, ifElement);
            if not Assigned(collectionItem) then
            begin
              case propertyItem.PropertyType of
                ptSimple: collectionName  := propertyItem.TranslatedName + CollectionPostfix;
                ptItem:   collectionName  := propertyItem.TranslatedName + CollectionPostfix;
              end;

              collectionItem                := TXMLDataBindingInterface.Create(Self, propertyItem.SchemaItem, collectionName);
              collectionItem.CollectionItem := propertyItem;
              ASchema.InsertItem(collectionItem, interfaceItem);
            end;

            propertyItem.Collection := collectionItem;
          end;
        end;
      end;
    finally
      FreeAndNil(repeatingItems);
    end;
  end;
end;


function TXMLDataBindingGenerator.TranslateItemName(AItem: TXMLDataBindingItem): String;
begin
  Result := AItem.Name;
end;


function TXMLDataBindingGenerator.GetSchemaCount: Integer;
begin
  Result  := FSchemas.Count;
end;


function TXMLDataBindingGenerator.GetSchemas(Index: Integer): TXMLDataBindingSchema;
begin
  Result  := TXMLDataBindingSchema(FSchemas[Index]);
end;


{ TXMLDataBindingGeneratorItem }
constructor TXMLDataBindingGeneratorItem.Create(AOwner: TXMLDataBindingGenerator);
begin
  inherited Create;

  FOwner  := AOwner;
end;


procedure TXMLDataBindingGeneratorItem.ReplaceItem(const AOldItem, ANewItem: TXMLDataBindingItem);
begin
end;


{ TXMLDataBindingSchema }
constructor TXMLDataBindingSchema.Create(AOwner: TXMLDataBindingGenerator);
begin
  inherited Create(AOwner);

  FIncludes := TObjectList.Create(False);
  FItems := TObjectList.Create(True);
end;


destructor TXMLDataBindingSchema.Destroy;
begin
  FreeAndNil(FItems);
  FreeAndNil(FIncludes);

  inherited;
end;


procedure TXMLDataBindingSchema.ReplaceItem(const AOldItem, ANewItem: TXMLDataBindingItem);
var
  itemIndex:    Integer;

begin
  inherited;

  for itemIndex := Pred(ItemCount) downto 0 do
    if Items[itemIndex] = AOldItem then
      FItems.Extract(AOldItem)
    else
      Items[itemIndex].ReplaceItem(AOldItem, ANewItem);
end;


procedure TXMLDataBindingSchema.AddInclude(ASchema: TXMLDataBindingSchema);
begin
  if FIncludes.IndexOf(ASchema) = -1 then
    FIncludes.Add(ASchema);
end;


procedure TXMLDataBindingSchema.AddItem(AItem: TXMLDataBindingItem);
begin
  if FItems.IndexOf(AItem) = -1 then
  begin
    FItems.Add(AItem);
    AItem.Schema  := Self;
  end;
end;


procedure TXMLDataBindingSchema.InsertItem(AItem, AAfter: TXMLDataBindingItem);
var
  itemIndex:  Integer;

begin
  if FItems.IndexOf(AItem) = -1 then
  begin
    itemIndex := FItems.IndexOf(AAfter);
    if itemIndex > -1 then
      FItems.Insert(Succ(itemIndex), AItem)
    else
      FItems.Add(AItem);

    AItem.Schema  := Self;
  end;
end;


function TXMLDataBindingSchema.GetIncludeCount: Integer;
begin
  Result  := FIncludes.Count;
end;


function TXMLDataBindingSchema.GetIncludes(Index: Integer): TXMLDataBindingSchema;
begin
  Result  := TXMLDataBindingSchema(FIncludes[Index]);
end;


function TXMLDataBindingSchema.GetItemCount: Integer;
begin
  Result  := FItems.Count;
end;


function TXMLDataBindingSchema.GetItems(Index: Integer): TXMLDataBindingItem;
begin
  Result  := TXMLDataBindingItem(FItems[Index]);
end;


function TXMLDataBindingSchema.GetTargetNamespace: String;
begin
  Result  := '';
  if Assigned(FSchemaDef) and (not VarIsNull(FSchemaDef.TargetNamespace)) then
    Result  := FSchemaDef.TargetNamespace;
end;


{ TXMLDataBindingItem }
constructor TXMLDataBindingItem.Create(AOwner: TXMLDataBindingGenerator; ASchemaItem: IXMLSchemaItem; const AName: String);
begin
  inherited Create(AOwner);

  FName := AName;
  FSchemaItem := ASchemaItem;
  FTranslatedName := AName;
end;


function TXMLDataBindingItem.GetDocumentation: String;
var
  documentationIndex: Integer;

begin
  Result  := '';
  if HasDocumentation then
  begin
    for documentationIndex := 0 to Pred(SchemaItem.Documentation.Count) do
      Result  := Result + SchemaItem.Documentation[documentationIndex].Text + #13#10;

    Result  := Trim(Result);
  end;
end;


function TXMLDataBindingItem.GetHasDocumentation: Boolean;
begin
  Result  := Assigned(SchemaItem) and
             (SchemaItem.Documentation.Count > 0);
end;


function TXMLDataBindingItem.GetIsCollection: Boolean;
begin
  Result  := Assigned(FCollectionItem);
end;


procedure TXMLDataBindingItem.SetName(const Value: String);
begin
  FName := Value;
end;


{ TXMLDataBindingInterface }
constructor TXMLDataBindingInterface.Create(AOwner: TXMLDataBindingGenerator; ASchemaItem: IXMLSchemaItem; const AName: String);
var
  elementDef:   IXMLElementDef;
  compositor:   IXMLElementCompositor;

begin
  inherited Create(AOwner, ASchemaItem, AName);

  FProperties := TObjectList.Create(True);
  FInterfaceType := GetInterfaceType(SchemaItem);
  FIsSequence := False;

  if Supports(ASchemaItem, IXMLElementDef, elementDef) then
  begin
    { To access the compositor, we need to go through a ChildElement's ParentNode.

      Tried but did not work:
        ASchemaItem as IXMLElementCompositor
        ASchemaItem.ChildNodes[0] as IXMLElementCompositor
    }
    if elementDef.ChildElements.Count > 0 then
    begin
      if Supports(elementDef.ChildElements[0].ParentNode, IXMLElementCompositor, compositor) then
        FIsSequence := (compositor.CompositorType = ctSequence);
    end;
  end;
end;


destructor TXMLDataBindingInterface.Destroy;
begin
  FreeAndNil(FProperties);

  inherited;
end;


procedure TXMLDataBindingInterface.ReplaceItem(const AOldItem, ANewItem: TXMLDataBindingItem);
var
  propertyIndex:    Integer;
  propertyItem:     TXMLDataBindingProperty;
  itemProperty:     TXMLDataBindingItemProperty;
  simpleProperty:   TXMLDataBindingSimpleProperty;

begin
  inherited;

  for propertyIndex := Pred(PropertyCount) downto 0 do
  begin
    propertyItem  := Properties[propertyIndex];

    if propertyItem = AOldItem then
      FProperties.Extract(AOldItem)
    else
    begin
      if (AOldItem.ItemType = itSimpleTypeAlias) and
         (propertyItem.PropertyType = ptItem) then
      begin
        itemProperty  := TXMLDataBindingItemProperty(propertyItem);

        if itemProperty.Item = AOldItem then
        begin
          { Replace item property with simple property }
          simpleProperty  := TXMLDataBindingSimpleProperty.CreateFromAlias(Owner, itemProperty, TXMLDataBindingSimpleTypeAliasItem(AOldItem).DataType);

          { FProperties owns itemProperty and will free it }
          FProperties[propertyIndex]  := simpleProperty;
        end else
          Properties[propertyIndex].ReplaceItem(AOldItem, ANewItem);
      end else
        Properties[propertyIndex].ReplaceItem(AOldItem, ANewItem);
    end;
  end;
end;


procedure TXMLDataBindingInterface.AddProperty(AProperty: TXMLDataBindingProperty);
begin
  FProperties.Add(AProperty);
end;


function TXMLDataBindingInterface.GetCanValidate: Boolean;
var
  propertyIndex: Integer;
  elementCount: Integer;
  requiredCount: Integer;
  propertyItem: TXMLDataBindingProperty;

begin
  Result := False;

  elementCount := 0;
  requiredCount := 0;

  for propertyIndex := 0 to Pred(PropertyCount) do
  begin
    propertyItem := Properties[propertyIndex];

    if propertyItem.IsAttribute then
    begin
      if not propertyItem.IsOptional then
        Inc(requiredCount);
    end else
    begin
      Inc(elementCount);
      if not propertyItem.IsOptional then
        Inc(requiredCount);
    end;
  end;


  { If there's a required element or attribute,
     we can validate their presence. }
  if requiredCount > 0 then
    Result := True

  { If our children are a sequence and there's at least two elements,
    we can validate their order. }
  else if IsSequence and (elementCount > 1) then
    Result := True;
end;


function TXMLDataBindingInterface.GetItemType: TXMLDataBindingItemType;
begin
  Result  := itInterface;
end;


function TXMLDataBindingInterface.GetPropertyCount: Integer;
begin
  Result := FProperties.Count;
end;


function TXMLDataBindingInterface.GetProperties(Index: Integer): TXMLDataBindingProperty;
begin
  Result := TXMLDataBindingProperty(FProperties[Index]);
end;


{ TXMLDataBindingEnumerationMember }
constructor TXMLDataBindingEnumerationMember.Create(AOwner: TXMLDataBindingGenerator; AEnumeration: TXMLDataBindingEnumeration; const AName: String);
begin
  inherited Create(AOwner, nil, AName);

  FEnumeration  := AEnumeration;
end;


function TXMLDataBindingEnumerationMember.GetItemType: TXMLDataBindingItemType;
begin
  Result := itEnumerationMember;
end;


{ TXMLDataBindingEnumeration }
constructor TXMLDataBindingEnumeration.Create(AOwner: TXMLDataBindingGenerator; ASchemaItem: IXMLSchemaItem; AEnumerations: IXMLEnumerationCollection; const AName: String; AIsAttribute: Boolean);
var
  memberIndex:  Integer;

begin
  inherited Create(AOwner, ASchemaItem, AName);

  FMembers      := TObjectList.Create;
  FIsAttribute  := AIsAttribute;

  for memberIndex := 0 to Pred(AEnumerations.Count) do
    FMembers.Add(TXMLDataBindingEnumerationMember.Create(Owner, Self, AEnumerations.Items[memberIndex].Value));
end;


destructor TXMLDataBindingEnumeration.Destroy;
begin
  FreeAndNil(FMembers);

  inherited;
end;


function TXMLDataBindingEnumeration.GetItemType: TXMLDataBindingItemType;
begin
  Result  := itEnumeration;
end;


function TXMLDataBindingEnumeration.GetMemberCount: Integer;
begin
  Result  := FMembers.Count;
end;


function TXMLDataBindingEnumeration.GetMembers(Index: Integer): TXMLDataBindingEnumerationMember;
begin
  Result  := TXMLDataBindingEnumerationMember(FMembers[Index]);
end;


{ TXMLDataBindingProperty }
function TXMLDataBindingProperty.GetItemType: TXMLDataBindingItemType;
begin
  Result := itProperty;
end;


{ TXMLDataBindingSimpleProperty }
constructor TXMLDataBindingSimpleProperty.Create(AOwner: TXMLDataBindingGenerator; ASchemaItem: IXMLSchemaItem; const AName: String; ADataType: IXMLTypeDef);
begin
  inherited Create(AOwner, ASchemaItem, AName);

  FDataType := ADataType;
end;


constructor TXMLDataBindingSimpleProperty.CreateFromAlias(AOwner: TXMLDataBindingGenerator; AProperty: TXMLDataBindingItemProperty; ADataType: IXMLTypeDef);
begin
  Create(AOwner, AProperty.SchemaItem, AProperty.Name, ADataType);

  IsAttribute := AProperty.IsAttribute;
  IsOptional  := AProperty.IsOptional;
  IsNillable  := AProperty.IsNillable;
  IsRepeating := AProperty.IsRepeating;
end;


function TXMLDataBindingSimpleProperty.GetIsReadOnly: Boolean;
begin
  Result := False;
end;


function TXMLDataBindingSimpleProperty.GetPropertyType: TXMLDataBindingPropertyType;
begin
  Result := ptSimple;
end;


{ TXMLDataBindingItemProperty }
constructor TXMLDataBindingItemProperty.Create(AOwner: TXMLDataBindingGenerator; ASchemaItem: IXMLSchemaItem; const AName: String; AItem: TXMLDataBindingItem);
begin
  inherited Create(AOwner, ASchemaItem, AName);

  FItem := AItem;
end;


procedure TXMLDataBindingItemProperty.ReplaceItem(const AOldItem, ANewItem: TXMLDataBindingItem);
begin
  inherited;

  if FItem = AOldItem then
    FItem := ANewItem;
end;


function TXMLDataBindingItemProperty.GetIsReadOnly: Boolean;
begin
  Result := Assigned(Item) and (Item.ItemType <> itEnumeration);
end;


function TXMLDataBindingItemProperty.GetPropertyType: TXMLDataBindingPropertyType;
begin
  Result := ptItem;
end;


{ TXMLDataBindingUnresolvedItem }
constructor TXMLDataBindingUnresolvedItem.Create(AOwner: TXMLDataBindingGenerator; ASchemaItem: IXMLSchemaItem; const AName: String; AInterfaceType: TXMLDataBindingInterfaceType; AIsAttribute: Boolean);
begin
  inherited Create(AOwner, ASchemaItem, AName);

  FInterfaceType  := AInterfaceType;
  FIsAttribute    := AIsAttribute;
end;


function TXMLDataBindingUnresolvedItem.GetItemType: TXMLDataBindingItemType;
begin
  Result  := itUnresolved;
end;


{ TXMLDataBindingComplexTypeAliasItem }
procedure TXMLDataBindingComplexTypeAliasItem.ReplaceItem(const AOldItem, ANewItem: TXMLDataBindingItem);
begin
  inherited;

  if FItem = AOldItem then
    FItem := ANewItem;
end;


function TXMLDataBindingComplexTypeAliasItem.GetItemType: TXMLDataBindingItemType;
begin
  Result  := itComplexTypeAlias;
end;


{ TXMLDataBindingSimpleTypeAliasItem }
function TXMLDataBindingSimpleTypeAliasItem.GetItemType: TXMLDataBindingItemType;
begin
  Result  := itSimpleTypeAlias;
end;

end.



