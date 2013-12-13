unit Generics.Collections.Query;

interface
uses
  System.Generics.Collections, System.SysUtils;

type
  TQueryEnumerator<T> = class(TEnumerator<T>)
  protected
    FUpstreamEnumerator : TEnumerator<T>;
    function DoGetCurrent: T; override;
    function DoMoveNext: Boolean; override;
  public
    constructor Create(Enumerator : TEnumerator<T>); virtual;
    destructor Destroy; override;
    function GetEnumerator: TQueryEnumerator<T>;
    ///	<summary>
    ///	  Use Take when you want to limit the number of items that will be
    ///	  enumerated.
    ///	</summary>
    ///	<param name="Count">
    ///	  The maximum number of items to enumerate.
    ///	</param>
    ///	<returns>
    ///	  Returns another TQueryEnumerator, so you can call other operators,
    ///	  such as�Where, to further filter the items enumerated.
    ///	</returns>
    ///	<remarks>
    ///	  Note, it is possible to return less than Count items, if there are
    ///	  fewer items in the collection, or fewer items left after earlier
    ///	  operators (such as Where)
    ///	</remarks>
    function Take(Count : Integer): TQueryEnumerator<T>;
    ///	<summary>
    ///	  Filter the items enumerated to only those that evaluate true when
    ///	  passed into the Predicate
    ///	</summary>
    ///	<param name="Predicate">
    ///	  An anonymous method that will be executed in turn against each item.
    ///	  It should return True to include the item in the result, False to
    ///	  exclude it. �
    ///	</param>
    ///	<returns>
    ///	  Returns another TQueryEnumerator, so you can call other operators,
    ///	  such as Take or even another Where�operator to further filter the
    ///	  items.�
    ///	</returns>
    function Where(Predicate : TPredicate<T>) : TQueryEnumerator<T>;
    property Current: T read DoGetCurrent;
  end;

  TTakeEnumerator<T> = class(TQueryEnumerator<T>)
  private
    FMaxPassCount: Integer;
    FPassCount : Integer;
  protected
    function DoMoveNext: Boolean; override;
  public
    constructor Create(Enumerator : TEnumerator<T>; PassCount : Integer); reintroduce;
    property MaxPassCount : Integer read FMaxPassCount write FMaxPassCount;
  end;

  TWhereEnumerator<T> = class(TQueryEnumerator<T>)
  private
    FWherePredicate : TPredicate<T>;
  protected
    function DoMoveNext: Boolean; override;
    function ShouldIncludeItem : Boolean;
  public
    constructor Create(Enumerator : TEnumerator<T>; Predicate : TPredicate<T>); reintroduce;
  end;

  ///	<summary>
  ///	  Starting point of your query.
  ///	</summary>
  ///	<typeparam name="T">
  ///	  The type of the individual items in the collection you are enumerating.
  ///	  ie. If your From method (which comes next) specifies a
  ///	  TList&lt;TPerson&gt;, T here will be a TPerson
  ///	</typeparam>
  Query<T> = class
    ///	<summary>
    ///	  The second part of your query, specifying the source data from which
    ///	  you wish to query.
    ///	</summary>
    class function From(Collection : TEnumerable<T>) : TQueryEnumerator<T> ;
  end;


implementation


{ Query<T> }

class function Query<T>.From(Collection: TEnumerable<T>): TQueryEnumerator<T>;
begin
  Result := TQueryEnumerator<T>.Create(Collection.GetEnumerator);
end;

{ TQueryEnumerator<T> }

constructor TQueryEnumerator<T>.Create(Enumerator: TEnumerator<T>);
begin
  FUpstreamEnumerator := Enumerator;
end;

destructor TQueryEnumerator<T>.Destroy;
begin
  FUpstreamEnumerator.Free;
  inherited;
end;

function TQueryEnumerator<T>.DoGetCurrent: T;
begin
  Result := FUpstreamEnumerator.Current;
end;

function TQueryEnumerator<T>.DoMoveNext: Boolean;
begin
  Result := FUpstreamEnumerator.MoveNext;
end;

function TQueryEnumerator<T>.GetEnumerator: TQueryEnumerator<T>;
begin
  Result := self;
end;

function TQueryEnumerator<T>.Take(Count: Integer): TQueryEnumerator<T>;
begin
  Result := TTakeEnumerator<T>.Create(self, Count);
end;

function TQueryEnumerator<T>.Where(
  Predicate: TPredicate<T>): TQueryEnumerator<T>;
begin
  Result := TWhereEnumerator<T>.Create(self, Predicate);
end;

{ TAtMostEnumerator<T> }

constructor TTakeEnumerator<T>.Create(Enumerator: TEnumerator<T>; PassCount : Integer);
begin
  inherited Create(Enumerator);
  FPassCount := 0;
  FMaxPassCount := PassCount;
end;

function TTakeEnumerator<T>.DoMoveNext: Boolean;
begin
  Result := FPassCount < FMaxPassCount;

  if Result then
  begin
    Result := inherited DoMoveNext;
    Inc(FPassCount);
  end;
end;

{ TWhereEnumerator<T> }

constructor TWhereEnumerator<T>.Create(Enumerator: TEnumerator<T>;
  Predicate: TPredicate<T>);
begin
  inherited Create(Enumerator);
  FWherePredicate := Predicate;
end;

function TWhereEnumerator<T>.DoMoveNext: Boolean;
var
  IsDone : Boolean;
begin
  inherited DoMoveNext;

  repeat
    IsDone := ShouldIncludeItem;
  until IsDone or (not inherited DoMoveNext);

  Result := IsDone;
end;


function TWhereEnumerator<T>.ShouldIncludeItem: Boolean;
begin
    try
      if Assigned(FWherePredicate) then
        Result := FWherePredicate(Current)
      else
        Result := False;
    except
      on E : EArgumentOutOfRangeException do
        Result := False;
    end;
end;



end.