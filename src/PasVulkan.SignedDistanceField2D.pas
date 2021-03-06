(******************************************************************************
 *                                 PasVulkan                                  *
 ******************************************************************************
 *                       Version see PasVulkan.Framework.pas                  *
 ******************************************************************************
 *                                zlib license                                *
 *============================================================================*
 *                                                                            *
 * Copyright (C) 2016-2020, Benjamin Rosseaux (benjamin@rosseaux.de)          *
 *                                                                            *
 * This software is provided 'as-is', without any express or implied          *
 * warranty. In no event will the authors be held liable for any damages      *
 * arising from the use of this software.                                     *
 *                                                                            *
 * Permission is granted to anyone to use this software for any purpose,      *
 * including commercial applications, and to alter it and redistribute it     *
 * freely, subject to the following restrictions:                             *
 *                                                                            *
 * 1. The origin of this software must not be misrepresented; you must not    *
 *    claim that you wrote the original software. If you use this software    *
 *    in a product, an acknowledgement in the product documentation would be  *
 *    appreciated but is not required.                                        *
 * 2. Altered source versions must be plainly marked as such, and must not be *
 *    misrepresented as being the original software.                          *
 * 3. This notice may not be removed or altered from any source distribution. *
 *                                                                            *
 ******************************************************************************
 *                  General guidelines for code contributors                  *
 *============================================================================*
 *                                                                            *
 * 1. Make sure you are legally allowed to make a contribution under the zlib *
 *    license.                                                                *
 * 2. The zlib license header goes at the top of each source file, with       *
 *    appropriate copyright notice.                                           *
 * 3. This PasVulkan wrapper may be used only with the PasVulkan-own Vulkan   *
 *    Pascal header.                                                          *
 * 4. After a pull request, check the status of your pull request on          *
      http://github.com/BeRo1985/pasvulkan                                    *
 * 5. Write code which's compatible with Delphi >= 2009 and FreePascal >=     *
 *    3.1.1                                                                   *
 * 6. Don't use Delphi-only, FreePascal-only or Lazarus-only libraries/units, *
 *    but if needed, make it out-ifdef-able.                                  *
 * 7. No use of third-party libraries/units as possible, but if needed, make  *
 *    it out-ifdef-able.                                                      *
 * 8. Try to use const when possible.                                         *
 * 9. Make sure to comment out writeln, used while debugging.                 *
 * 10. Make sure the code compiles on 32-bit and 64-bit platforms (x86-32,    *
 *     x86-64, ARM, ARM64, etc.).                                             *
 * 11. Make sure the code runs on all platforms with Vulkan support           *
 *                                                                            *
 ******************************************************************************)
unit PasVulkan.SignedDistanceField2D;
{$i PasVulkan.inc}
{$ifndef fpc}
 {$ifdef conditionalexpressions}
  {$if CompilerVersion>=24.0}
   {$legacyifend on}
  {$ifend}
 {$endif}
{$endif}
{$m+}

interface

uses SysUtils,
     Classes,
     Math,
     PUCU,
     PasMP,
     Vulkan,
     PasVulkan.Types,
     PasVulkan.Math,
     PasVulkan.Collections,
     PasVulkan.Framework,
     PasVulkan.VectorPath,
     PasVulkan.Sprites;

type PpvSignedDistanceField2DPixel=^TpvSignedDistanceField2DPixel;
     TpvSignedDistanceField2DPixel=packed record
      r,g,b,a:TpvUInt8;
     end;

     TpvSignedDistanceField2DPixels=array of TpvSignedDistanceField2DPixel;

     PpvSignedDistanceField2D=^TpvSignedDistanceField2D;
     TpvSignedDistanceField2D=record
      Width:TpvInt32;
      Height:TpvInt32;
      Pixels:TpvSignedDistanceField2DPixels;
     end;

     TpvSignedDistanceField2DArray=array of TpvSignedDistanceField2D;

     PpvSignedDistanceField2DPathSegmentSide=^TpvSignedDistanceField2DPathSegmentSide;
     TpvSignedDistanceField2DPathSegmentSide=
      (
       Left=-1,
       On=0,
       Right=1,
       None=2
      );

     PpvSignedDistanceField2DDataItem=^TpvSignedDistanceField2DDataItem;
     TpvSignedDistanceField2DDataItem=record
      SquaredDistance:TpvFloat;
      SquaredDistanceR:TpvFloat;
      SquaredDistanceG:TpvFloat;
      SquaredDistanceB:TpvFloat;
      PseudoSquaredDistanceR:TpvFloat;
      PseudoSquaredDistanceG:TpvFloat;
      PseudoSquaredDistanceB:TpvFloat;
      DeltaWindingScore:TpvInt32;
     end;

     TpvSignedDistanceField2DData=array of TpvSignedDistanceField2DDataItem;

     PpvSignedDistanceField2DDoublePrecisionPoint=^TpvSignedDistanceField2DDoublePrecisionPoint;
     TpvSignedDistanceField2DDoublePrecisionPoint=record
      x:TpvDouble;
      y:TpvDouble;
     end;

     PpvSignedDistanceField2DDoublePrecisionAffineMatrix=^TpvSignedDistanceField2DDoublePrecisionAffineMatrix;
     TpvSignedDistanceField2DDoublePrecisionAffineMatrix=array[0..5] of TpvDouble;

     PpvSignedDistanceField2DPathSegmentType=^TpvSignedDistanceField2DPathSegmentType;
     TpvSignedDistanceField2DPathSegmentType=
      (
       Line,
       QuadraticBezierCurve
      );

     PpvSignedDistanceField2DBoundingBox=^TpvSignedDistanceField2DBoundingBox;
     TpvSignedDistanceField2DBoundingBox=record
      Min:TpvSignedDistanceField2DDoublePrecisionPoint;
      Max:TpvSignedDistanceField2DDoublePrecisionPoint;
     end;

     PpvSignedDistanceField2DPathSegmentColor=^TpvSignedDistanceField2DPathSegmentColor;
     TpvSignedDistanceField2DPathSegmentColor=
      (
       Black=0,
       Red=1,
       Green=2,
       Yellow=3,
       Blue=4,
       Magenta=5,
       Cyan=6,
       White=7
      );

     PpvSignedDistanceField2DPathSegmentPoints=^TpvSignedDistanceField2DPathSegmentPoints;
     TpvSignedDistanceField2DPathSegmentPoints=array[0..2] of TpvSignedDistanceField2DDoublePrecisionPoint;

     PpvSignedDistanceField2DPathSegment=^TpvSignedDistanceField2DPathSegment;
     TpvSignedDistanceField2DPathSegment=record
      Type_:TpvSignedDistanceField2DPathSegmentType;
      Color:TpvSignedDistanceField2DPathSegmentColor;
      Points:TpvSignedDistanceField2DPathSegmentPoints;
      P0T,P2T:TpvSignedDistanceField2DDoublePrecisionPoint;
      XFormMatrix:TpvSignedDistanceField2DDoublePrecisionAffineMatrix;
      ScalingFactor:TpvDouble;
      SquaredScalingFactor:TpvDouble;
      NearlyZeroScaled:TpvDouble;
      SquaredTangentToleranceScaled:TpvDouble;
      BoundingBox:TpvSignedDistanceField2DBoundingBox;
     end;

     TpvSignedDistanceField2DPathSegments=array of TpvSignedDistanceField2DPathSegment;

     PpvSignedDistanceField2DPathContour=^TpvSignedDistanceField2DPathContour;
     TpvSignedDistanceField2DPathContour=record
      PathSegments:TpvSignedDistanceField2DPathSegments;
      CountPathSegments:TpvInt32;
     end;

     TpvSignedDistanceField2DPathContours=array of TpvSignedDistanceField2DPathContour;

     PpvSignedDistanceField2DShape=^TpvSignedDistanceField2DShape;
     TpvSignedDistanceField2DShape=record
      Contours:TpvSignedDistanceField2DPathContours;
      CountContours:TpvInt32;
     end;

     PpvSignedDistanceField2DRowDataIntersectionType=^TpvSignedDistanceField2DRowDataIntersectionType;
     TpvSignedDistanceField2DRowDataIntersectionType=
      (
       NoIntersection,
       VerticalLine,
       TangentLine,
       TwoPointsIntersect
      );

     PpvSignedDistanceField2DRowData=^TpvSignedDistanceField2DRowData;
     TpvSignedDistanceField2DRowData=record
      IntersectionType:TpvSignedDistanceField2DRowDataIntersectionType;
      QuadraticXDirection:TpvInt32;
      ScanlineXDirection:TpvInt32;
      YAtIntersection:TpvFloat;
      XAtIntersection:array[0..1] of TpvFloat;
     end;

     PpvSignedDistanceField2DPointInPolygonPathSegment=^TpvSignedDistanceField2DPointInPolygonPathSegment;
     TpvSignedDistanceField2DPointInPolygonPathSegment=record
      Points:array[0..1] of TpvSignedDistanceField2DDoublePrecisionPoint;
     end;

     TpvSignedDistanceField2DPointInPolygonPathSegments=array of TpvSignedDistanceField2DPointInPolygonPathSegment;

     TpvSignedDistanceField2DGenerator=class
      private
       const DistanceField2DMagnitudeValue=VulkanDistanceField2DSpreadValue;
             DistanceField2DPadValue=VulkanDistanceField2DSpreadValue;
             DistanceField2DScalar1Value=1.0;
             DistanceField2DCloseValue=DistanceField2DScalar1Value/16.0;
             DistanceField2DCloseSquaredValue=DistanceField2DCloseValue*DistanceField2DCloseValue;
             DistanceField2DNearlyZeroValue=DistanceField2DScalar1Value/int64(1 shl 18);
             DistanceField2DTangentToleranceValue=DistanceField2DScalar1Value/int64(1 shl 11);
             DistanceField2DRasterizerToScreenScale=1.0;
             CurveTessellationTolerance=0.125;
             CurveTessellationToleranceSquared=CurveTessellationTolerance*CurveTessellationTolerance;
             CurveRecursionLimit=16;
      private
       fPointInPolygonPathSegments:TpvSignedDistanceField2DPointInPolygonPathSegments;
       fVectorPath:TpvVectorPath;
       fScale:TpvDouble;
       fOffsetX:TpvDouble;
       fOffsetY:TpvDouble;
       fDistanceField:PpvSignedDistanceField2D;
       fMultiChannel:boolean;
       fShape:TpvSignedDistanceField2DShape;
       fDistanceFieldData:TpvSignedDistanceField2DData;
      protected
       function Clamp(const Value,MinValue,MaxValue:TpvInt64):TpvInt64; overload;
       function Clamp(const Value,MinValue,MaxValue:TpvDouble):TpvDouble; overload;
       function DoublePrecisionPointAdd(const a,b:TpvSignedDistanceField2DDoublePrecisionPoint):TpvSignedDistanceField2DDoublePrecisionPoint;
       function DoublePrecisionPointSub(const a,b:TpvSignedDistanceField2DDoublePrecisionPoint):TpvSignedDistanceField2DDoublePrecisionPoint;
       function DoublePrecisionPointLength(const p:TpvSignedDistanceField2DDoublePrecisionPoint):TpvDouble;
       function DoublePrecisionPointDistance(const a,b:TpvSignedDistanceField2DDoublePrecisionPoint):TpvDouble;
       function DoublePrecisionPointLengthSquared(const v:TpvSignedDistanceField2DDoublePrecisionPoint):TpvDouble;
       function DoublePrecisionPointDistanceSquared(const a,b:TpvSignedDistanceField2DDoublePrecisionPoint):TpvDouble;
       function DoublePrecisionPointCrossProduct(const a,b:TpvSignedDistanceField2DDoublePrecisionPoint):TpvDouble;
       function DoublePrecisionPointIsLeft(const a,b,c:TpvSignedDistanceField2DDoublePrecisionPoint):TpvDouble;
       function DoublePrecisionPointDotProduct(const a,b:TpvSignedDistanceField2DDoublePrecisionPoint):TpvDouble;
       function DoublePrecisionPointNormalize(const v:TpvSignedDistanceField2DDoublePrecisionPoint):TpvSignedDistanceField2DDoublePrecisionPoint;
       function DoublePrecisionPointLerp(const a,b:TpvSignedDistanceField2DDoublePrecisionPoint;const t:TpvDouble):TpvSignedDistanceField2DDoublePrecisionPoint;
       function DoublePrecisionPointMap(const p:TpvSignedDistanceField2DDoublePrecisionPoint;const m:TpvSignedDistanceField2DDoublePrecisionAffineMatrix):TpvSignedDistanceField2DDoublePrecisionPoint;
       function BetweenClosedOpen(const a,b,c:TpvDouble;const Tolerance:TpvDouble=0.0;const XFormToleranceToX:boolean=false):boolean;
       function BetweenClosed(const a,b,c:TpvDouble;const Tolerance:TpvDouble=0.0;const XFormToleranceToX:boolean=false):boolean;
       function NearlyZero(const Value:TpvDouble;const Tolerance:TpvDouble=DistanceField2DNearlyZeroValue):boolean;
       function NearlyEqual(const x,y:TpvDouble;const Tolerance:TpvDouble=DistanceField2DNearlyZeroValue;const XFormToleranceToX:boolean=false):boolean;
       function SignOf(const Value:TpvDouble):TpvInt32;
       function IsColinear(const Points:array of TpvSignedDistanceField2DDoublePrecisionPoint):boolean;
       function PathSegmentDirection(const PathSegment:TpvSignedDistanceField2DPathSegment;const Which:TpvInt32):TpvSignedDistanceField2DDoublePrecisionPoint;
       function PathSegmentCountPoints(const PathSegment:TpvSignedDistanceField2DPathSegment):TpvInt32;
       function PathSegmentEndPoint(const PathSegment:TpvSignedDistanceField2DPathSegment):PpvSignedDistanceField2DDoublePrecisionPoint;
       function PathSegmentCornerPoint(const PathSegment:TpvSignedDistanceField2DPathSegment;const WhichA,WhichB:TpvInt32):PpvSignedDistanceField2DDoublePrecisionPoint;
       procedure InitializePathSegment(var PathSegment:TpvSignedDistanceField2DPathSegment);
       procedure InitializeDistances;
       function AddLineToPathSegmentArray(var Contour:TpvSignedDistanceField2DPathContour;const Points:array of TpvSignedDistanceField2DDoublePrecisionPoint):TpvInt32;
       function AddQuadraticBezierCurveToPathSegmentArray(var Contour:TpvSignedDistanceField2DPathContour;const Points:array of TpvSignedDistanceField2DDoublePrecisionPoint):TpvInt32;
       function AddQuadraticBezierCurveAsSubdividedLinesToPathSegmentArray(var Contour:TpvSignedDistanceField2DPathContour;const Points:array of TpvSignedDistanceField2DDoublePrecisionPoint):TpvInt32;
       function AddCubicBezierCurveAsSubdividedQuadraticBezierCurvesToPathSegmentArray(var Contour:TpvSignedDistanceField2DPathContour;const Points:array of TpvSignedDistanceField2DDoublePrecisionPoint):TpvInt32;
       function AddCubicBezierCurveAsSubdividedLinesToPathSegmentArray(var Contour:TpvSignedDistanceField2DPathContour;const Points:array of TpvSignedDistanceField2DDoublePrecisionPoint):TpvInt32;
       function CubeRoot(Value:TpvDouble):TpvDouble;
       function CalculateNearestPointForQuadraticBezierCurve(const PathSegment:TpvSignedDistanceField2DPathSegment;const XFormPoint:TpvSignedDistanceField2DDoublePrecisionPoint):TpvDouble;
       procedure PrecomputationForRow(out RowData:TpvSignedDistanceField2DRowData;const PathSegment:TpvSignedDistanceField2DPathSegment;const PointLeft,PointRight:TpvSignedDistanceField2DDoublePrecisionPoint);
       function CalculateSideOfQuadraticBezierCurve(const PathSegment:TpvSignedDistanceField2DPathSegment;const Point,XFormPoint:TpvSignedDistanceField2DDoublePrecisionPoint;const RowData:TpvSignedDistanceField2DRowData):TpvSignedDistanceField2DPathSegmentSide;
       function DistanceToPathSegment(const Point:TpvSignedDistanceField2DDoublePrecisionPoint;const PathSegment:TpvSignedDistanceField2DPathSegment;const RowData:TpvSignedDistanceField2DRowData;out PathSegmentSide:TpvSignedDistanceField2DPathSegmentSide):TpvDouble;
       procedure ConvertShape(const DoSubdivideCurvesIntoLines:boolean);
       procedure SplitPathSegmentIntoThreePartsInsideContour(var Contour:TpvSignedDistanceField2DPathContour;const BasePathSegmentIndex:TpvInt32);
       procedure SplitPathSegmentIntoThreePartsToContour(var Contour:TpvSignedDistanceField2DPathContour;const BasePathSegmentIndex:TpvInt32;const BasePathSegment:TpvSignedDistanceField2DPathSegment);
       procedure NormalizeShape;
       procedure PathSegmentColorizeShape;
       function GetLineNonClippedTime(const p,p0,p1:TpvSignedDistanceField2DDoublePrecisionPoint):TpvDouble;
       function GetQuadraticBezierCurveNonClippedTime(const p,p0,p1,p2:TpvSignedDistanceField2DDoublePrecisionPoint):TpvDouble;
       function GetNonClampedSignedLineDistance(const p,p0,p1:TpvSignedDistanceField2DDoublePrecisionPoint):TpvDouble;
       procedure CalculateDistanceFieldDataLineRange(const FromY,ToY:TpvInt32);
       procedure CalculateDistanceFieldDataLineRangeParallelForJobFunction(const Job:PPasMPJob;const ThreadIndex:TPasMPInt32;const Data:TpvPointer;const FromIndex,ToIndex:TPasMPNativeInt);
       function PackDistanceFieldValue(Distance:TpvDouble):TpvUInt8;
       function PackPseudoDistanceFieldValue(Distance:TpvDouble):TpvUInt8;
       procedure ConvertToPointInPolygonPathSegments;
       function GetWindingNumberAtPointInPolygon(const Point:TpvSignedDistanceField2DDoublePrecisionPoint):TpvInt32;
       function GenerateDistanceFieldPicture(const DistanceFieldData:TpvSignedDistanceField2DData;const Width,Height,TryIteration:TpvInt32):boolean;
      public
       constructor Create; reintroduce;
       destructor Destroy; override;
       procedure Execute(var aDistanceField:TpvSignedDistanceField2D;const aVectorPath:TpvVectorPath;const aScale:TpvDouble=1.0;const aOffsetX:TpvDouble=0.0;const aOffsetY:TpvDouble=0.0;const aMultiChannel:boolean=false);
       class procedure Generate(var aDistanceField:TpvSignedDistanceField2D;const aVectorPath:TpvVectorPath;const aScale:TpvDouble=1.0;const aOffsetX:TpvDouble=0.0;const aOffsetY:TpvDouble=0.0;const aMultiChannel:boolean=false); static;
     end;

implementation

constructor TpvSignedDistanceField2DGenerator.Create;
begin
 inherited Create;
 fPointInPolygonPathSegments:=nil;
 fVectorPath:=nil;
 fDistanceField:=nil;
 fMultiChannel:=false;
end;

destructor TpvSignedDistanceField2DGenerator.Destroy;
begin
 fPointInPolygonPathSegments:=nil;
 fVectorPath:=nil;
 fDistanceField:=nil;
 inherited Destroy;
end;

function TpvSignedDistanceField2DGenerator.Clamp(const Value,MinValue,MaxValue:TpvInt64):TpvInt64;
begin
 if Value<=MinValue then begin
  result:=MinValue;
 end else if Value>=MaxValue then begin
  result:=MaxValue;
 end else begin
  result:=Value;
 end;
end;

function TpvSignedDistanceField2DGenerator.Clamp(const Value,MinValue,MaxValue:TpvDouble):TpvDouble;
begin
 if Value<=MinValue then begin
  result:=MinValue;
 end else if Value>=MaxValue then begin
  result:=MaxValue;
 end else begin
  result:=Value;
 end;
end;

function TpvSignedDistanceField2DGenerator.DoublePrecisionPointAdd(const a,b:TpvSignedDistanceField2DDoublePrecisionPoint):TpvSignedDistanceField2DDoublePrecisionPoint;
begin
 result.x:=a.x+b.x;
 result.y:=a.y+b.y;
end;

function TpvSignedDistanceField2DGenerator.DoublePrecisionPointSub(const a,b:TpvSignedDistanceField2DDoublePrecisionPoint):TpvSignedDistanceField2DDoublePrecisionPoint;
begin
 result.x:=a.x-b.x;
 result.y:=a.y-b.y;
end;

function TpvSignedDistanceField2DGenerator.DoublePrecisionPointLength(const p:TpvSignedDistanceField2DDoublePrecisionPoint):TpvDouble;
begin
 result:=sqrt(sqr(p.x)+sqr(p.y));
end;

function TpvSignedDistanceField2DGenerator.DoublePrecisionPointDistance(const a,b:TpvSignedDistanceField2DDoublePrecisionPoint):TpvDouble;
begin
 result:=sqrt(sqr(a.x-b.x)+sqr(a.y-b.y));
end;

function TpvSignedDistanceField2DGenerator.DoublePrecisionPointLengthSquared(const v:TpvSignedDistanceField2DDoublePrecisionPoint):TpvDouble;
begin
 result:=sqr(v.x)+sqr(v.y);
end;

function TpvSignedDistanceField2DGenerator.DoublePrecisionPointDistanceSquared(const a,b:TpvSignedDistanceField2DDoublePrecisionPoint):TpvDouble;
begin
 result:=sqr(a.x-b.x)+sqr(a.y-b.y);
end;

function TpvSignedDistanceField2DGenerator.DoublePrecisionPointCrossProduct(const a,b:TpvSignedDistanceField2DDoublePrecisionPoint):TpvDouble;
begin
 result:=(a.x*b.y)-(a.y*b.x);
end;

function TpvSignedDistanceField2DGenerator.DoublePrecisionPointIsLeft(const a,b,c:TpvSignedDistanceField2DDoublePrecisionPoint):TpvDouble;
begin
 result:=((b.x*a.x)*(c.y*a.y))-((c.x*a.x)*(b.y*a.y));
end;

function TpvSignedDistanceField2DGenerator.DoublePrecisionPointDotProduct(const a,b:TpvSignedDistanceField2DDoublePrecisionPoint):TpvDouble;
begin
 result:=(a.x*b.x)+(a.y*b.y);
end;

function TpvSignedDistanceField2DGenerator.DoublePrecisionPointNormalize(const v:TpvSignedDistanceField2DDoublePrecisionPoint):TpvSignedDistanceField2DDoublePrecisionPoint;
var f:TpvDouble;
begin
 f:=sqr(v.x)+sqr(v.y);
 if IsZero(f) then begin
  result.x:=0.0;
  result.y:=0.0;
 end else begin
  result.x:=v.x/f;
  result.y:=v.y/f;
 end;
end;

function TpvSignedDistanceField2DGenerator.DoublePrecisionPointLerp(const a,b:TpvSignedDistanceField2DDoublePrecisionPoint;const t:TpvDouble):TpvSignedDistanceField2DDoublePrecisionPoint;
begin
 if t<=0.0 then begin
  result:=a;
 end else if t>=1.0 then begin
  result:=b;
 end else begin
  result.x:=(a.x*(1.0-t))+(b.x*t);
  result.y:=(a.y*(1.0-t))+(b.y*t);
 end;
end;

function TpvSignedDistanceField2DGenerator.DoublePrecisionPointMap(const p:TpvSignedDistanceField2DDoublePrecisionPoint;const m:TpvSignedDistanceField2DDoublePrecisionAffineMatrix):TpvSignedDistanceField2DDoublePrecisionPoint;
begin
 result.x:=(p.x*m[0])+(p.y*m[1])+m[2];
 result.y:=(p.x*m[3])+(p.y*m[4])+m[5];
end;

function TpvSignedDistanceField2DGenerator.BetweenClosedOpen(const a,b,c:TpvDouble;const Tolerance:TpvDouble=0.0;const XFormToleranceToX:boolean=false):boolean;
var ToleranceB,ToleranceC:TpvDouble;
begin
 Assert(Tolerance>=0.0);
 if XFormToleranceToX then begin
  ToleranceB:=Tolerance/sqrt((sqr(b)*4.0)+1.0);
  ToleranceC:=Tolerance/sqrt((sqr(c)*4.0)+1.0);
 end else begin
  ToleranceB:=Tolerance;
  ToleranceC:=Tolerance;
 end;
 if b<c then begin
  result:=(a>=(b-ToleranceB)) and (a<(c-ToleranceC));
 end else begin
  result:=(a>=(c-ToleranceC)) and (a<(b-ToleranceB));
 end;
end;

function TpvSignedDistanceField2DGenerator.BetweenClosed(const a,b,c:TpvDouble;const Tolerance:TpvDouble=0.0;const XFormToleranceToX:boolean=false):boolean;
var ToleranceB,ToleranceC:TpvDouble;
begin
 Assert(Tolerance>=0.0);
 if XFormToleranceToX then begin
  ToleranceB:=Tolerance/sqrt((sqr(b)*4.0)+1.0);
  ToleranceC:=Tolerance/sqrt((sqr(c)*4.0)+1.0);
 end else begin
  ToleranceB:=Tolerance;
  ToleranceC:=Tolerance;
 end;
 if b<c then begin
  result:=(a>=(b-ToleranceB)) and (a<=(c+ToleranceC));
 end else begin
  result:=(a>=(c-ToleranceC)) and (a<=(b+ToleranceB));
 end;
end;

function TpvSignedDistanceField2DGenerator.NearlyZero(const Value:TpvDouble;const Tolerance:TpvDouble=DistanceField2DNearlyZeroValue):boolean;
begin
 Assert(Tolerance>=0.0);
 result:=abs(Value)<=Tolerance;
end;

function TpvSignedDistanceField2DGenerator.NearlyEqual(const x,y:TpvDouble;const Tolerance:TpvDouble=DistanceField2DNearlyZeroValue;const XFormToleranceToX:boolean=false):boolean;
begin
 Assert(Tolerance>=0.0);
 if XFormToleranceToX then begin
  result:=abs(x-y)<=(Tolerance/sqrt((sqr(y)*4.0)+1.0));
 end else begin
  result:=abs(x-y)<=Tolerance;
 end;
end;

function TpvSignedDistanceField2DGenerator.SignOf(const Value:TpvDouble):TpvInt32;
begin
 if Value<0.0 then begin
  result:=-1;
 end else begin
  result:=1;
 end;
end;

function TpvSignedDistanceField2DGenerator.IsColinear(const Points:array of TpvSignedDistanceField2DDoublePrecisionPoint):boolean;
begin
 Assert(length(Points)=3);
 result:=abs(((Points[1].y-Points[0].y)*(Points[1].x-Points[2].x))-
             ((Points[1].y-Points[2].y)*(Points[1].x-Points[0].x)))<=DistanceField2DCloseSquaredValue;
end;

function TpvSignedDistanceField2DGenerator.PathSegmentDirection(const PathSegment:TpvSignedDistanceField2DPathSegment;const Which:TpvInt32):TpvSignedDistanceField2DDoublePrecisionPoint;
begin
 case PathSegment.Type_ of
  TpvSignedDistanceField2DPathSegmentType.Line:begin
   result.x:=PathSegment.Points[1].x-PathSegment.Points[0].x;
   result.y:=PathSegment.Points[1].y-PathSegment.Points[0].y;
  end;
  TpvSignedDistanceField2DPathSegmentType.QuadraticBezierCurve:begin
   case Which of
    0:begin
     result.x:=PathSegment.Points[1].x-PathSegment.Points[0].x;
     result.y:=PathSegment.Points[1].y-PathSegment.Points[0].y;
    end;
    1:begin
     result.x:=PathSegment.Points[2].x-PathSegment.Points[1].x;
     result.y:=PathSegment.Points[2].y-PathSegment.Points[1].y;
    end;
    else begin
     result.x:=0.0;
     result.y:=0.0;
     Assert(false);
    end;
   end;
  end;
  else begin
   result.x:=0.0;
   result.y:=0.0;
   Assert(false);
  end;
 end;
end;

function TpvSignedDistanceField2DGenerator.PathSegmentCountPoints(const PathSegment:TpvSignedDistanceField2DPathSegment):TpvInt32;
begin
 case PathSegment.Type_ of
  TpvSignedDistanceField2DPathSegmentType.Line:begin
   result:=2;
  end;
  TpvSignedDistanceField2DPathSegmentType.QuadraticBezierCurve:begin
   result:=3;
  end;
  else begin
   result:=0;
   Assert(false);
  end;
 end;
end;

function TpvSignedDistanceField2DGenerator.PathSegmentEndPoint(const PathSegment:TpvSignedDistanceField2DPathSegment):PpvSignedDistanceField2DDoublePrecisionPoint;
begin
 case PathSegment.Type_ of
  TpvSignedDistanceField2DPathSegmentType.Line:begin
   result:=@PathSegment.Points[1];
  end;
  TpvSignedDistanceField2DPathSegmentType.QuadraticBezierCurve:begin
   result:=@PathSegment.Points[2];
  end;
  else begin
   result:=nil;
   Assert(false);
  end;
 end;
end;

function TpvSignedDistanceField2DGenerator.PathSegmentCornerPoint(const PathSegment:TpvSignedDistanceField2DPathSegment;const WhichA,WhichB:TpvInt32):PpvSignedDistanceField2DDoublePrecisionPoint;
begin
 case PathSegment.Type_ of
  TpvSignedDistanceField2DPathSegmentType.Line:begin
   result:=@PathSegment.Points[WhichB and 1];
  end;
  TpvSignedDistanceField2DPathSegmentType.QuadraticBezierCurve:begin
   result:=@PathSegment.Points[(WhichA and 1)+(WhichB and 1)];
  end;
  else begin
   result:=nil;
   Assert(false);
  end;
 end;
end;

procedure TpvSignedDistanceField2DGenerator.InitializePathSegment(var PathSegment:TpvSignedDistanceField2DPathSegment);
var p0,p1,p2,p1mp0,d,t,sp0,sp1,sp2,p01p,p02p,p12p:TpvSignedDistanceField2DDoublePrecisionPoint;
    Hypotenuse,CosTheta,SinTheta,a,b,h,c,g,f,gd,fd,x,y,Lambda:TpvDouble;
begin
 case PathSegment.Type_ of
  TpvSignedDistanceField2DPathSegmentType.Line:begin
   p0:=PathSegment.Points[0];
   p2:=PathSegment.Points[1];
   PathSegment.BoundingBox.Min.x:=Min(p0.x,p2.x);
   PathSegment.BoundingBox.Min.y:=Min(p0.y,p2.y);
   PathSegment.BoundingBox.Max.x:=Max(p0.x,p2.x);
   PathSegment.BoundingBox.Max.y:=Max(p0.y,p2.y);
   PathSegment.ScalingFactor:=1.0;
   PathSegment.SquaredScalingFactor:=1.0;
   Hypotenuse:=DoublePrecisionPointDistance(p0,p2);
   CosTheta:=(p2.x-p0.x)/Hypotenuse;
   SinTheta:=(p2.y-p0.y)/Hypotenuse;
   PathSegment.XFormMatrix[0]:=CosTheta;
   PathSegment.XFormMatrix[1]:=SinTheta;
   PathSegment.XFormMatrix[2]:=(-(CosTheta*p0.x))-(SinTheta*p0.y);
   PathSegment.XFormMatrix[3]:=-SinTheta;
   PathSegment.XFormMatrix[4]:=CosTheta;
   PathSegment.XFormMatrix[5]:=(SinTheta*p0.x)-(CosTheta*p0.y);
  end;
  else {pstQuad:}begin
   p0:=PathSegment.Points[0];
   p1:=PathSegment.Points[1];
   p2:=PathSegment.Points[2];
   PathSegment.BoundingBox.Min.x:=Min(p0.x,p2.x);
   PathSegment.BoundingBox.Min.y:=Min(p0.y,p2.y);
   PathSegment.BoundingBox.Max.x:=Max(p0.x,p2.x);
   PathSegment.BoundingBox.Max.y:=Max(p0.y,p2.y);
   p1mp0.x:=p1.x-p0.x;
   p1mp0.y:=p1.y-p0.y;
   d.x:=(p1mp0.x-p2.x)+p1.x;
   d.y:=(p1mp0.y-p2.y)+p1.y;
   if IsZero(d.x) then begin
    t.x:=p0.x;
   end else begin
    t.x:=p0.x+(Clamp(p1mp0.x/d.x,0.0,1.0)*p1mp0.x);
   end;
   if IsZero(d.y) then begin
    t.y:=p0.y;
   end else begin
    t.y:=p0.y+(Clamp(p1mp0.y/d.y,0.0,1.0)*p1mp0.y);
   end;
   PathSegment.BoundingBox.Min.x:=Min(PathSegment.BoundingBox.Min.x,t.x);
   PathSegment.BoundingBox.Min.y:=Min(PathSegment.BoundingBox.Min.y,t.y);
   PathSegment.BoundingBox.Max.x:=Max(PathSegment.BoundingBox.Max.x,t.x);
   PathSegment.BoundingBox.Max.y:=Max(PathSegment.BoundingBox.Max.y,t.y);
   sp0.x:=sqr(p0.x);
   sp0.y:=sqr(p0.y);
   sp1.x:=sqr(p1.x);
   sp1.y:=sqr(p1.y);
   sp2.x:=sqr(p2.x);
   sp2.y:=sqr(p2.y);
   p01p.x:=p0.x*p1.x;
   p01p.y:=p0.y*p1.y;
   p02p.x:=p0.x*p2.x;
   p02p.y:=p0.y*p2.y;
   p12p.x:=p1.x*p2.x;
   p12p.y:=p1.y*p2.y;
   a:=sqr((p0.y-(2.0*p1.y))+p2.y);
   h:=-(((p0.y-(2.0*p1.y))+p2.y)*((p0.x-(2.0*p1.x))+p2.x));
   b:=sqr((p0.x-(2.0*p1.x))+p2.x);
   c:=((((((sp0.x*sp2.y)-(4.0*p01p.x*p12p.y))-(2.0*p02p.x*p02p.y))+(4.0*p02p.x*sp1.y))+(4.0*sp1.x*p02p.y))-(4.0*p12p.x*p01p.y))+(sp2.x*sp0.y);
   g:=((((((((((p0.x*p02p.y)-(2.0*p0.x*sp1.y))+(2.0*p0.x*p12p.y))-(p0.x*sp2.y))+(2.0*p1.x*p01p.y))-(4.0*p1.x*p02p.y))+(2.0*p1.x*p12p.y))-(p2.x*sp0.y))+(2.0*p2.x*p01p.y))+(p2.x*p02p.y))-(2.0*p2.x*sp1.y);
   f:=-(((((((((((sp0.x*p2.y)-(2.0*p01p.x*p1.y))-(2.0*p01p.x*p2.y))-(p02p.x*p0.y))+(4.0*p02p.x*p1.y))-(p02p.x*p2.y))+(2.0*sp1.x*p0.y))+(2.0*sp1.x*p2.y))-(2.0*p12p.x*p0.y))-(2.0*p12p.x*p1.y))+(sp2.x*p0.y));
   CosTheta:=sqrt(a/(a+b));
   SinTheta:=(-SignOf((a+b)*h))*sqrt(b/(a+b));
   gd:=(CosTheta*g)-(SinTheta*f);
   fd:=(SinTheta*g)+(CosTheta*f);
   x:=gd/(a+b);
   y:=(1.0/(2.0*fd))*(c-(sqr(gd)/(a+b)));
   Lambda:=-((a+b)/(2.0*fd));
   PathSegment.ScalingFactor:=abs(1.0/Lambda);
   PathSegment.SquaredScalingFactor:=sqr(PathSegment.ScalingFactor);
   CosTheta:=CosTheta*Lambda;
   SinTheta:=SinTheta*Lambda;
   PathSegment.XFormMatrix[0]:=CosTheta;
   PathSegment.XFormMatrix[1]:=-SinTheta;
   PathSegment.XFormMatrix[2]:=x*Lambda;
   PathSegment.XFormMatrix[3]:=SinTheta;
   PathSegment.XFormMatrix[4]:=CosTheta;
   PathSegment.XFormMatrix[5]:=y*Lambda;
  end;
 end;
 PathSegment.NearlyZeroScaled:=DistanceField2DNearlyZeroValue/PathSegment.ScalingFactor;
 PathSegment.SquaredTangentToleranceScaled:=sqr(DistanceField2DTangentToleranceValue)/PathSegment.SquaredScalingFactor;
 PathSegment.P0T:=DoublePrecisionPointMap(p0,PathSegment.XFormMatrix);
 PathSegment.P2T:=DoublePrecisionPointMap(p2,PathSegment.XFormMatrix);
end;

procedure TpvSignedDistanceField2DGenerator.InitializeDistances;
var Index:TpvInt32;
begin
 for Index:=0 to length(fDistanceFieldData)-1 do begin
  fDistanceFieldData[Index].SquaredDistance:=sqr(DistanceField2DMagnitudeValue);
  fDistanceFieldData[Index].SquaredDistanceR:=sqr(DistanceField2DMagnitudeValue);
  fDistanceFieldData[Index].SquaredDistanceG:=sqr(DistanceField2DMagnitudeValue);
  fDistanceFieldData[Index].SquaredDistanceB:=sqr(DistanceField2DMagnitudeValue);
  fDistanceFieldData[Index].PseudoSquaredDistanceR:=sqr(DistanceField2DMagnitudeValue);
  fDistanceFieldData[Index].PseudoSquaredDistanceG:=sqr(DistanceField2DMagnitudeValue);
  fDistanceFieldData[Index].PseudoSquaredDistanceB:=sqr(DistanceField2DMagnitudeValue);
  fDistanceFieldData[Index].DeltaWindingScore:=0;
 end;
end;

function TpvSignedDistanceField2DGenerator.AddLineToPathSegmentArray(var Contour:TpvSignedDistanceField2DPathContour;const Points:array of TpvSignedDistanceField2DDoublePrecisionPoint):TpvInt32;
var PathSegment:PpvSignedDistanceField2DPathSegment;
begin
 Assert(length(Points)=2);
 result:=Contour.CountPathSegments;
 if not (SameValue(Points[0].x,Points[1].x) and SameValue(Points[0].y,Points[1].y)) then begin
  inc(Contour.CountPathSegments);
  if length(Contour.PathSegments)<=Contour.CountPathSegments then begin
   SetLength(Contour.PathSegments,Contour.CountPathSegments*2);
  end;
  PathSegment:=@Contour.PathSegments[result];
  PathSegment^.Type_:=TpvSignedDistanceField2DPathSegmentType.Line;
  PathSegment^.Color:=TpvSignedDistanceField2DPathSegmentColor.Black;
  PathSegment^.Points[0]:=Points[0];
  PathSegment^.Points[1]:=Points[1];
  InitializePathSegment(PathSegment^);
 end;
end;

function TpvSignedDistanceField2DGenerator.AddQuadraticBezierCurveToPathSegmentArray(var Contour:TpvSignedDistanceField2DPathContour;const Points:array of TpvSignedDistanceField2DDoublePrecisionPoint):TpvInt32;
var PathSegment:PpvSignedDistanceField2DPathSegment;
begin
 Assert(length(Points)=3);
 result:=Contour.CountPathSegments;
 if (DoublePrecisionPointDistanceSquared(Points[0],Points[1])<DistanceField2DCloseSquaredValue) or
    (DoublePrecisionPointDistanceSquared(Points[1],Points[2])<DistanceField2DCloseSquaredValue) or
    IsColinear(Points) then begin
  if not (SameValue(Points[0].x,Points[2].x) and SameValue(Points[0].y,Points[2].y)) then begin
   inc(Contour.CountPathSegments);
   if length(Contour.PathSegments)<=Contour.CountPathSegments then begin
    SetLength(Contour.PathSegments,Contour.CountPathSegments*2);
   end;
   PathSegment:=@Contour.PathSegments[result];
   PathSegment^.Type_:=TpvSignedDistanceField2DPathSegmentType.Line;
   PathSegment^.Color:=TpvSignedDistanceField2DPathSegmentColor.Black;
   PathSegment^.Points[0]:=Points[0];
   PathSegment^.Points[1]:=Points[2];
   InitializePathSegment(PathSegment^);
  end;
 end else begin
  inc(Contour.CountPathSegments);
  if length(Contour.PathSegments)<=Contour.CountPathSegments then begin
   SetLength(Contour.PathSegments,Contour.CountPathSegments*2);
  end;
  PathSegment:=@Contour.PathSegments[result];
  PathSegment^.Type_:=TpvSignedDistanceField2DPathSegmentType.QuadraticBezierCurve;
  PathSegment^.Color:=TpvSignedDistanceField2DPathSegmentColor.Black;
  PathSegment^.Points[0]:=Points[0];
  PathSegment^.Points[1]:=Points[1];
  PathSegment^.Points[2]:=Points[2];
  InitializePathSegment(PathSegment^);
 end;
end;

function TpvSignedDistanceField2DGenerator.AddQuadraticBezierCurveAsSubdividedLinesToPathSegmentArray(var Contour:TpvSignedDistanceField2DPathContour;const Points:array of TpvSignedDistanceField2DDoublePrecisionPoint):TpvInt32;
var LastPoint:TpvSignedDistanceField2DDoublePrecisionPoint;
 procedure LineToPointAt(const Point:TpvSignedDistanceField2DDoublePrecisionPoint);
 begin
  if not (SameValue(LastPoint.x,Point.x) and SameValue(LastPoint.y,Point.y)) then begin
   AddLineToPathSegmentArray(Contour,[LastPoint,Point]);
  end;
  LastPoint:=Point;
 end;
 procedure Recursive(const x1,y1,x2,y2,x3,y3:TpvDouble;const Level:TpvInt32);
 var x12,y12,x23,y23,x123,y123,dx,dy:TpvDouble;
     Point:TpvSignedDistanceField2DDoublePrecisionPoint;
 begin
  x12:=(x1+x2)*0.5;
  y12:=(y1+y2)*0.5;
  x23:=(x2+x3)*0.5;
  y23:=(y2+y3)*0.5;
  x123:=(x12+x23)*0.5;
  y123:=(y12+y23)*0.5;
  dx:=x3-x1;
  dy:=y3-y1;
  if (Level>CurveRecursionLimit) or
     ((Level>0) and
      (sqr(((x2-x3)*dy)-((y2-y3)*dx))<((sqr(dx)+sqr(dy))*CurveTessellationToleranceSquared))) then begin
   Point.x:=x3;
   Point.y:=y3;
   LineToPointAt(Point);
  end else begin
   Recursive(x1,y1,x12,y12,x123,y123,Level+1);
   Recursive(x123,y123,x23,y23,x3,y3,Level+1);
  end;
 end;
begin
 Assert(length(Points)=3);
 result:=Contour.CountPathSegments;
 LastPoint:=Points[0];
 Recursive(Points[0].x,Points[0].y,Points[1].x,Points[1].y,Points[2].x,Points[2].y,0);
 LineToPointAt(Points[2]);
end;

function TpvSignedDistanceField2DGenerator.AddCubicBezierCurveAsSubdividedQuadraticBezierCurvesToPathSegmentArray(var Contour:TpvSignedDistanceField2DPathContour;const Points:array of TpvSignedDistanceField2DDoublePrecisionPoint):TpvInt32;
type TLine=record
      a,b,c:TpvDouble;
      Exist,Vertical:boolean;
     end;
     TPointLine=record
      p:TpvSignedDistanceField2DDoublePrecisionPoint;
      l:TLine;
     end;
var LastPoint:TpvSignedDistanceField2DDoublePrecisionPoint;
 procedure MoveTo(const p:TpvSignedDistanceField2DDoublePrecisionPoint);
 begin
  LastPoint:=p;
 end;
 procedure LineTo(const p:TpvSignedDistanceField2DDoublePrecisionPoint);
 begin
  if not (SameValue(LastPoint.x,p.x) and SameValue(LastPoint.y,p.y)) then begin
   AddLineToPathSegmentArray(Contour,[LastPoint,p]);
  end;
  LastPoint:=p;
 end;
 procedure CurveTo(const p0,p1:TpvSignedDistanceField2DDoublePrecisionPoint);
 begin
  AddQuadraticBezierCurveToPathSegmentArray(Contour,[LastPoint,p0,p1]);
  LastPoint:=p1;
 end;
 function GetLine(const P0,P1:TpvSignedDistanceField2DDoublePrecisionPoint):TLine;
 begin
  FillChar(result,SizeOf(TLine),#0);
  if SameValue(P0.x,P1.x) then begin
   if SameValue(P0.y,P1.y) then begin
    // P0 and P1 are same point, return null
    result.Exist:=false;
    result.Vertical:=false;
   end else begin
    // Otherwise, the line is a vertical line
    result.Exist:=true;
    result.Vertical:=true;
    result.c:=P0.x;
   end;
  end else begin
   result.Exist:=true;
   result.Vertical:=false;
   result.a:=(P0.y-P1.y)/(P0.x-P1.x);
   result.b:=P0.y-(result.a*P0.x);
  end;
 end;
 function GetLine2(const P0,v0:TpvSignedDistanceField2DDoublePrecisionPoint):TLine;
 begin
  FillChar(result,SizeOf(TLine),#0);
  result.Exist:=true;
  if IsZero(v0.x) then begin
   // The line is vertical
   result.Vertical:=true;
   result.c:=p0.x;
  end else begin
   result.Vertical:=false;
   result.a:=v0.y/v0.x;
   result.b:=P0.y-(result.a*P0.x);
  end;
 end;
 function GetLineCross(const l0,l1:TLine;var b:boolean):TpvSignedDistanceField2DDoublePrecisionPoint;
 var u:TpvDouble;
 begin

  result.x:=0.0;
  result.y:=0.0;

  // Make sure both line exists
  b:=false;
  if (not l0.exist) or (not l1.exist) then begin
   exit;
  end;

  // Checks whether both lines are vertical
  if (not l0.vertical) and (not l1.vertical) then begin

   // Lines are not verticals but parallel, intersection does not exist
   if l0.a=l1.a then begin
    exit;
   end;

   // Calculate common x value.
   u:=(l1.b-l0.b)/(l0.a-l1.a);

   // Return the new point
   result.x:=u;
   result.y:=(l0.a*u)+l0.b;
  end else begin
   if l0.Vertical then begin
    if l1.Vertical then begin
     // Both lines vertical, intersection does not exist
     exit;
    end else begin
     // Return the point on l1 with x = c0
     result.x:=l0.c;
     result.y:=(l1.a*l0.c)+l1.b;
    end;
   end else if l1.Vertical then begin
    // No need to test c0 as it was tested above, return the point on l0 with x = c1
    result.x:=l1.c;
    result.y:=(l0.a*l1.c)+l0.b;
   end;
  end;

  // We're done!
  b:=true;
 end;
 function GetCubicPoint(const c0,c1,c2,c3,t:TpvDouble):TpvDouble;
 var ts,g,b,a:TpvDouble;
 begin
  ts:=t*t;
  g:=3*(c1-c0);
  b:=(3*(c2-c1))-g;
  a:=((c3-c0)-b)-g;
  result:=(a*ts*t)+(b*ts)+(g*t)+c0;
 end;
 function GetCubicDerivative(const c0,c1,c2,c3,t:TpvDouble):TpvDouble;
 var g,b,a:TpvDouble;
 begin
  g:=3*(c1-c0);
  b:=(3*(c2-c1))-g;
  a:=((c3-c0)-b)-g;
  result:=(3*a*t*t)+(2*b*t)+g;
 end;
 function GetCubicTangent(const P0,P1,P2,P3:TpvSignedDistanceField2DDoublePrecisionPoint;t:TpvDouble):TPointLine;
 var P,V:TpvSignedDistanceField2DDoublePrecisionPoint;
     l:TLine;
 begin

  // Calculates the position of the cubic bezier at t
  P.x:=GetCubicPoint(P0.x,P1.x,P2.x,P3.x,t);
  P.y:=GetCubicPoint(P0.y,P1.y,P2.y,P3.y,t);

  // Calculates the tangent values of the cubic bezier at t
  V.x:=GetCubicDerivative(P0.x,P1.x,P2.x,P3.x,t);
  V.y:=GetCubicDerivative(P0.y,P1.y,P2.y,P3.y,t);

  // Calculates the line equation for the tangent at t
  l:=GetLine2(P,V);

  // Return the Point/Tangent object
  result.P:=P;
  result.l:=l;

 end;
 procedure CubicCurveToTangent(const P0,P1,P2,P3:TpvSignedDistanceField2DDoublePrecisionPoint);
 const NumberOfSegments=8;
  function SliceCubicBezierSegment(const p0,p1,p2,p3:TpvSignedDistanceField2DDoublePrecisionPoint;const u1,u2:TpvDouble;const Tu1,Tu2:TPointLine;Recursion:TpvInt32):TpvInt32;
  var P,ControlPoint:TpvSignedDistanceField2DDoublePrecisionPoint;
      b:boolean;
      d,uMid:TpvDouble;
      TuMid:TPointLine;
  begin

   // Prevents infinite recursion (no more than 10 levels) if 10 levels are reached the latest subsegment is approximated with a line (no quadratic curve). It should be good enough.
   if Recursion>10 then begin
    P:=Tu2.P;
    LineTo(P);
    result:=1;
    exit;
   end;

   // Recursion level is OK, process current segment
   ControlPoint:=GetLineCross(Tu1.l,Tu2.l,b);

   // A control point is considered misplaced if its distance from one of the anchor is greater
   // than the distance between the two anchors.
   d:=DoublePrecisionPointDistance(Tu1.P,Tu2.P);
   if (not b) or (DoublePrecisionPointDistance(Tu1.P,ControlPoint)>d) or (DoublePrecisionPointDistance(Tu2.P,ControlPoint)>d) then begin

    // Total for this subsegment starts at 0
    result:=0;

    // If the Control Point is misplaced, slice the segment more
    uMid:=(u1+u2)*0.5;
    TuMid:=GetCubicTangent(P0,P1,P2,P3,uMid);
    inc(result,SliceCubicBezierSegment(P0,P1,P2,P3,u1,uMid,Tu1,TuMid,Recursion+1));
    inc(result,SliceCubicBezierSegment(P0,P1,P2,P3,uMid,u2,TuMid,Tu2,Recursion+1));

   end else begin

    // If everything is OK draw curve
    P:=Tu2.P;
    CurveTo(ControlPoint,P);
    result:=1;

   end;
  end;
 var CurrentTime,NextTime:TPointLine;
     TimeStep:TpvDouble;
     i:TpvInt32;
 begin

  // Get the time step from number of output segments
  TimeStep:=1.0/NumberOfSegments;

  // Get the first tangent Object
  CurrentTime.P:=P0;
  CurrentTime.l:=GetLine(P0,P1);

  MoveTo(P0);

  // Get tangent objects for all intermediate segments and draw the segments
  for i:=1 to NumberOfSegments do begin

   // Get tangent object for next point
   NextTime:=GetCubicTangent(P0,P1,P2,P3,i*TimeStep);

   // Get segment data for the current segment
   SliceCubicBezierSegment(P0,P1,P2,P3,(i-1)*TimeStep,i*TimeStep,CurrentTime,NextTime,0);

   // Prepare for next round
   CurrentTime:=NextTime;

  end;

 end;
begin
 Assert(length(Points)=4);
 result:=Contour.CountPathSegments;
 CubicCurveToTangent(Points[0],Points[1],Points[2],Points[3]);
end;

function TpvSignedDistanceField2DGenerator.AddCubicBezierCurveAsSubdividedLinesToPathSegmentArray(var Contour:TpvSignedDistanceField2DPathContour;const Points:array of TpvSignedDistanceField2DDoublePrecisionPoint):TpvInt32;
var LastPoint:TpvSignedDistanceField2DDoublePrecisionPoint;
 procedure LineToPointAt(const Point:TpvSignedDistanceField2DDoublePrecisionPoint);
 begin
  if not (SameValue(LastPoint.x,Point.x) and SameValue(LastPoint.y,Point.y)) then begin
   AddLineToPathSegmentArray(Contour,[LastPoint,Point]);
  end;
  LastPoint:=Point;
 end;
 procedure Recursive(const x1,y1,x2,y2,x3,y3,x4,y4:TpvDouble;const Level:TpvInt32);
 var x12,y12,x23,y23,x34,y34,x123,y123,x234,y234,x1234,y1234,dx,dy:TpvDouble;
     Point:TpvSignedDistanceField2DDoublePrecisionPoint;
 begin
  x12:=(x1+x2)*0.5;
  y12:=(y1+y2)*0.5;
  x23:=(x2+x3)*0.5;
  y23:=(y2+y3)*0.5;
  x34:=(x3+x4)*0.5;
  y34:=(y3+y4)*0.5;
  x123:=(x12+x23)*0.5;
  y123:=(y12+y23)*0.5;
  x234:=(x23+x34)*0.5;
  y234:=(y23+y34)*0.5;
  x1234:=(x123+x234)*0.5;
  y1234:=(y123+y234)*0.5;
  dx:=x4-x1;
  dy:=y4-y1;
  if (Level>CurveRecursionLimit) or
     ((Level>0) and
      (sqr(abs(((x2-x4)*dy)-((y2-y4)*dx))+
           abs(((x3-x4)*dy)-((y3-y4)*dx)))<((sqr(dx)+sqr(dy))*CurveTessellationToleranceSquared))) then begin
   Point.x:=x4;
   Point.y:=y4;
   LineToPointAt(Point);
  end else begin
   Recursive(x1,y1,x12,y12,x123,y123,x1234,y1234,Level+1);
   Recursive(x1234,y1234,x234,y234,x34,y34,x4,y4,Level+1);
  end;
 end;
begin
 Assert(length(Points)=4);
 result:=Contour.CountPathSegments;
 LastPoint:=Points[0];
 Recursive(Points[0].x,Points[0].y,Points[1].x,Points[1].y,Points[2].x,Points[2].y,Points[3].x,Points[3].y,0);
 LineToPointAt(Points[3]);
end;

function TpvSignedDistanceField2DGenerator.CubeRoot(Value:TpvDouble):TpvDouble;
begin
 if IsZero(Value) then begin
  result:=0.0;
 end else begin
  result:=exp(ln(abs(Value))/3.0);
  if Value<0.0 then begin
   result:=-result;
  end;
 end;
end;

function TpvSignedDistanceField2DGenerator.CalculateNearestPointForQuadraticBezierCurve(const PathSegment:TpvSignedDistanceField2DPathSegment;const XFormPoint:TpvSignedDistanceField2DDoublePrecisionPoint):TpvDouble;
const OneDiv3=1.0/3.0;
      OneDiv27=1.0/27.0;
var a,b,a3,b2,c,SqrtC,CosPhi,Phi:TpvDouble;
begin
 a:=0.5-XFormPoint.y;
 b:=(-0.5)*XFormPoint.x;
 a3:=sqr(a)*a;
 b2:=sqr(b);
 c:=(b2*0.25)+(a3*OneDiv27);
 if c>=0.0 then begin
  SqrtC:=sqrt(c);
  b:=b*(-0.5);
  result:=CubeRoot(b+SqrtC)+CubeRoot(b-SqrtC);
 end else begin
  CosPhi:=sqrt((b2*0.25)*((-27.0)/a3));
  if b>0.0 then begin
   CosPhi:=-CosPhi;
  end;
  Phi:=ArcCos(CosPhi);
  if XFormPoint.x>0.0 then begin
   result:=2.0*sqrt(a*(-OneDiv3))*cos(Phi*OneDiv3);
   if not BetweenClosed(result,PathSegment.P0T.x,PathSegment.P2T.x) then begin
    result:=2.0*sqrt(a*(-OneDiv3))*cos((Phi*OneDiv3)+(pi*2.0*OneDiv3));
   end;
  end else begin
   result:=2.0*sqrt(a*(-OneDiv3))*cos((Phi*OneDiv3)+(pi*2.0*OneDiv3));
   if not BetweenClosed(result,PathSegment.P0T.x,PathSegment.P2T.x) then begin
    result:=2.0*sqrt(a*(-OneDiv3))*cos(Phi*OneDiv3);
   end;
  end;
 end;
end;

procedure TpvSignedDistanceField2DGenerator.PrecomputationForRow(out RowData:TpvSignedDistanceField2DRowData;const PathSegment:TpvSignedDistanceField2DPathSegment;const PointLeft,PointRight:TpvSignedDistanceField2DDoublePrecisionPoint);
var XFormPointLeft,XFormPointRight:TpvSignedDistanceField2DDoublePrecisionPoint;
    x0,y0,x1,y1,m,b,m2,c,Tolerance,d:TpvDouble;
begin
 if PathSegment.Type_=TpvSignedDistanceField2DPathSegmentType.QuadraticBezierCurve then begin
  XFormPointLeft:=DoublePrecisionPointMap(PointLeft,PathSegment.XFormMatrix);
  XFormPointRight:=DoublePrecisionPointMap(PointRight,PathSegment.XFormMatrix);
  RowData.QuadraticXDirection:=SignOf(PathSegment.P2T.x-PathSegment.P0T.x);
  RowData.ScanlineXDirection:=SignOf(XFormPointRight.x-XFormPointLeft.x);
  x0:=XFormPointLeft.x;
  y0:=XFormPointLeft.y;
  x1:=XFormPointRight.x;
  y1:=XFormPointRight.y;
  if NearlyEqual(x0,x1,PathSegment.NearlyZeroScaled,true) then begin
   RowData.IntersectionType:=TpvSignedDistanceField2DRowDataIntersectionType.VerticalLine;
   RowData.YAtIntersection:=sqr(x0);
   RowData.ScanlineXDirection:=0;
  end else begin
   m:=(y1-y0)/(x1-x0);
   b:=y0-(m*x0);
   m2:=sqr(m);
   c:=m2+(4.0*b);
   Tolerance:=(4.0*PathSegment.SquaredTangentToleranceScaled)/(m2+1.0);
   if (RowData.ScanlineXDirection=1) and
      (SameValue(PathSegment.Points[0].y,PointLeft.y) or
       SameValue(PathSegment.Points[2].y,PointLeft.y)) and
       NearlyZero(c,Tolerance) then begin
    RowData.IntersectionType:=TpvSignedDistanceField2DRowDataIntersectionType.TangentLine;
    RowData.XAtIntersection[0]:=m*0.5;
    RowData.XAtIntersection[1]:=m*0.5;
   end else if c<=0.0 then begin
    RowData.IntersectionType:=TpvSignedDistanceField2DRowDataIntersectionType.NoIntersection;
   end else begin
    RowData.IntersectionType:=TpvSignedDistanceField2DRowDataIntersectionType.TwoPointsIntersect;
    d:=sqrt(c);
    RowData.XAtIntersection[0]:=(m+d)*0.5;
    RowData.XAtIntersection[1]:=(m-d)*0.5;
   end;
  end;
 end;
end;

function TpvSignedDistanceField2DGenerator.CalculateSideOfQuadraticBezierCurve(const PathSegment:TpvSignedDistanceField2DPathSegment;const Point,XFormPoint:TpvSignedDistanceField2DDoublePrecisionPoint;const RowData:TpvSignedDistanceField2DRowData):TpvSignedDistanceField2DPathSegmentSide;
var p0,p1:TpvDouble;
    sp0,sp1:TpvInt32;
    ip0,ip1:boolean;
begin
 case RowData.IntersectionType of
  TpvSignedDistanceField2DRowDataIntersectionType.VerticalLine:begin
   result:=TpvSignedDistanceField2DPathSegmentSide(TpvInt32(SignOf(XFormPoint.y-RowData.YAtIntersection)*RowData.QuadraticXDirection));
  end;
  TpvSignedDistanceField2DRowDataIntersectionType.TwoPointsIntersect:begin
   result:=TpvSignedDistanceField2DPathSegmentSide.None;
   p0:=RowData.XAtIntersection[0];
   p1:=RowData.XAtIntersection[1];
   sp0:=SignOf(p0-XFormPoint.x);
   ip0:=true;
   ip1:=true;
   if RowData.ScanlineXDirection=1 then begin
    if ((RowData.QuadraticXDirection=-1) and
        (PathSegment.Points[0].y<=Point.y) and
        NearlyEqual(PathSegment.P0T.x,p0,PathSegment.NearlyZeroScaled,true)) or
       ((RowData.QuadraticXDirection=1) and
        (PathSegment.Points[2].y<=Point.y) and
        NearlyEqual(PathSegment.P2T.x,p0,PathSegment.NearlyZeroScaled,true)) then begin
     ip0:=false;
    end;
    if ((RowData.QuadraticXDirection=-1) and
        (PathSegment.Points[2].y<=Point.y) and
        NearlyEqual(PathSegment.P2T.x,p1,PathSegment.NearlyZeroScaled,true)) or
       ((RowData.QuadraticXDirection=1) and
        (PathSegment.Points[0].y<=Point.y) and
        NearlyEqual(PathSegment.P0T.x,p1,PathSegment.NearlyZeroScaled,true)) then begin
     ip1:=false;
    end;
   end;
   if ip0 and BetweenClosed(p0,PathSegment.P0T.x,PathSegment.P2T.x,PathSegment.NearlyZeroScaled,true) then begin
    result:=TpvSignedDistanceField2DPathSegmentSide(TpvInt32(sp0*RowData.QuadraticXDirection));
   end;
   if ip1 and BetweenClosed(p1,PathSegment.P0T.x,PathSegment.P2T.x,PathSegment.NearlyZeroScaled,true) then begin
    sp1:=SignOf(p1-XFormPoint.x);
    if (result=TpvSignedDistanceField2DPathSegmentSide.None) or (sp1=1) then begin
     result:=TpvSignedDistanceField2DPathSegmentSide(TpvInt32(-sp1*RowData.QuadraticXDirection));
    end;
   end;
  end;
  TpvSignedDistanceField2DRowDataIntersectionType.TangentLine:begin
   result:=TpvSignedDistanceField2DPathSegmentSide.None;
   if RowData.ScanlineXDirection=1 then begin
    if SameValue(PathSegment.Points[0].y,Point.y) then begin
     result:=TpvSignedDistanceField2DPathSegmentSide(TpvInt32(SignOf(RowData.XAtIntersection[0]-XFormPoint.x)));
    end else if SameValue(PathSegment.Points[2].y,Point.y) then begin
     result:=TpvSignedDistanceField2DPathSegmentSide(TpvInt32(SignOf(XFormPoint.x-RowData.XAtIntersection[0])));
    end;
   end;
  end;
  else begin
   result:=TpvSignedDistanceField2DPathSegmentSide.None;
  end;
 end;
end;

function TpvSignedDistanceField2DGenerator.DistanceToPathSegment(const Point:TpvSignedDistanceField2DDoublePrecisionPoint;const PathSegment:TpvSignedDistanceField2DPathSegment;const RowData:TpvSignedDistanceField2DRowData;out PathSegmentSide:TpvSignedDistanceField2DPathSegmentSide):TpvDouble;
var XFormPoint,x:TpvSignedDistanceField2DDoublePrecisionPoint;
    NearestPoint:TpvDouble;
begin
 XFormPoint:=DoublePrecisionPointMap(Point,PathSegment.XFormMatrix);
 case PathSegment.Type_ of
  TpvSignedDistanceField2DPathSegmentType.Line:begin
   if BetweenClosed(XFormPoint.x,PathSegment.P0T.x,PathSegment.P2T.x) then begin
    result:=sqr(XFormPoint.y);
   end else if XFormPoint.x<PathSegment.P0T.x then begin
    result:=sqr(XFormPoint.x)+sqr(XFormPoint.y);
   end else begin
    result:=sqr(XFormPoint.x-PathSegment.P2T.x)+sqr(XFormPoint.y);
   end;
   if BetweenClosedOpen(Point.y,PathSegment.BoundingBox.Min.y,PathSegment.BoundingBox.Max.y) then begin
    PathSegmentSide:=TpvSignedDistanceField2DPathSegmentSide(TpvInt32(SignOf(XFormPoint.y)));
   end else begin
    PathSegmentSide:=TpvSignedDistanceField2DPathSegmentSide.None;
   end;
  end;
  TpvSignedDistanceField2DPathSegmentType.QuadraticBezierCurve:begin
   NearestPoint:=CalculateNearestPointForQuadraticBezierCurve(PathSegment,XFormPoint);
   if BetweenClosed(NearestPoint,PathSegment.P0T.x,PathSegment.P2T.x) then begin
    x.x:=NearestPoint;
    x.y:=sqr(NearestPoint);
    result:=DoublePrecisionPointDistanceSquared(XFormPoint,x)*PathSegment.SquaredScalingFactor;
   end else begin
    result:=Min(DoublePrecisionPointDistanceSquared(XFormPoint,PathSegment.P0T),
                DoublePrecisionPointDistanceSquared(XFormPoint,PathSegment.P2T))*PathSegment.SquaredScalingFactor;
   end;
   if BetweenClosedOpen(Point.y,PathSegment.BoundingBox.Min.y,PathSegment.BoundingBox.Max.y) then begin
    PathSegmentSide:=CalculateSideOfQuadraticBezierCurve(PathSegment,Point,XFormPoint,RowData);
   end else begin
    PathSegmentSide:=TpvSignedDistanceField2DPathSegmentSide.None;
   end;
  end;
  else begin
   PathSegmentSide:=TpvSignedDistanceField2DPathSegmentSide.None;
   result:=0.0;
  end;
 end;
end;

procedure TpvSignedDistanceField2DGenerator.ConvertShape(const DoSubdivideCurvesIntoLines:boolean);
var CommandIndex:TpvInt32;
    Command:TpvVectorPathCommand;
    Contour:PpvSignedDistanceField2DPathContour;
    StartPoint,LastPoint,ControlPoint,OtherControlPoint,Point:TpvSignedDistanceField2DDoublePrecisionPoint;
    Scale:TpvDouble;
begin
 Scale:=fScale*DistanceField2DRasterizerToScreenScale;
 fShape.Contours:=nil;
 fShape.CountContours:=0;
 try
  Contour:=nil;
  try
   StartPoint.x:=0.0;
   StartPoint.y:=0.0;
   LastPoint.x:=0.0;
   LastPoint.y:=0.0;
   for CommandIndex:=0 to fVectorPath.Commands.Count-1 do begin
    Command:=fVectorPath.Commands[CommandIndex];
    case Command.CommandType of
     TpvVectorPathCommandType.MoveTo:begin
      if assigned(Contour) then begin
       if not (SameValue(LastPoint.x,StartPoint.x) and SameValue(LastPoint.y,StartPoint.y)) then begin
        AddLineToPathSegmentArray(Contour^,[LastPoint,StartPoint]);
       end;
       SetLength(Contour^.PathSegments,Contour^.CountPathSegments);
      end;
      if length(fShape.Contours)<(fShape.CountContours+1) then begin
       SetLength(fShape.Contours,(fShape.CountContours+1)*2);
      end;
      Contour:=@fShape.Contours[fShape.CountContours];
      inc(fShape.CountContours);
      LastPoint.x:=(Command.x0*Scale)+fOffsetX;
      LastPoint.y:=(Command.y0*Scale)+fOffsetY;
      StartPoint:=LastPoint;
     end;
     TpvVectorPathCommandType.LineTo:begin
      if not assigned(Contour) then begin
       if length(fShape.Contours)<(fShape.CountContours+1) then begin
        SetLength(fShape.Contours,(fShape.CountContours+1)*2);
       end;
       Contour:=@fShape.Contours[fShape.CountContours];
       inc(fShape.CountContours);
      end;
      Point.x:=(Command.x0*Scale)+fOffsetX;
      Point.y:=(Command.y0*Scale)+fOffsetY;
      if assigned(Contour) and not (SameValue(LastPoint.x,Point.x) and SameValue(LastPoint.y,Point.y)) then begin
       AddLineToPathSegmentArray(Contour^,[LastPoint,Point]);
      end;
      LastPoint:=Point;
     end;
     TpvVectorPathCommandType.QuadraticCurveTo:begin
      if not assigned(Contour) then begin
       if length(fShape.Contours)<(fShape.CountContours+1) then begin
        SetLength(fShape.Contours,(fShape.CountContours+1)*2);
       end;
       Contour:=@fShape.Contours[fShape.CountContours];
       inc(fShape.CountContours);
      end;
      ControlPoint.x:=(Command.x0*Scale)+fOffsetX;
      ControlPoint.y:=(Command.y0*Scale)+fOffsetY;
      Point.x:=(Command.x1*Scale)+fOffsetX;
      Point.y:=(Command.y1*Scale)+fOffsetY;
      if assigned(Contour) and not ((SameValue(LastPoint.x,Point.x) and SameValue(LastPoint.y,Point.y)) and
                                    (SameValue(LastPoint.x,ControlPoint.x) and SameValue(LastPoint.y,ControlPoint.y))) then begin
       if DoSubdivideCurvesIntoLines then begin
        AddQuadraticBezierCurveAsSubdividedLinesToPathSegmentArray(Contour^,[LastPoint,ControlPoint,Point]);
       end else begin
//      AddQuadraticBezierCurveAsSubdividedLinesToPathSegmentArray(Contour^,[LastPoint,ControlPoint,Point]);
        AddQuadraticBezierCurveToPathSegmentArray(Contour^,[LastPoint,ControlPoint,Point]);
       end;
      end;
      LastPoint:=Point;
     end;
     TpvVectorPathCommandType.CubicCurveTo:begin
      if not assigned(Contour) then begin
       if length(fShape.Contours)<(fShape.CountContours+1) then begin
        SetLength(fShape.Contours,(fShape.CountContours+1)*2);
       end;
       Contour:=@fShape.Contours[fShape.CountContours];
       inc(fShape.CountContours);
      end;
      ControlPoint.x:=(Command.x0*Scale)+fOffsetX;
      ControlPoint.y:=(Command.y0*Scale)+fOffsetY;
      OtherControlPoint.x:=(Command.x1*Scale)+fOffsetX;
      OtherControlPoint.y:=(Command.y1*Scale)+fOffsetY;
      Point.x:=(Command.x2*Scale)+fOffsetX;
      Point.y:=(Command.y2*Scale)+fOffsetY;
      if assigned(Contour) and not ((SameValue(LastPoint.x,Point.x) and SameValue(LastPoint.y,Point.y)) and
                                    (SameValue(LastPoint.x,OtherControlPoint.x) and SameValue(LastPoint.y,OtherControlPoint.y)) and
                                    (SameValue(LastPoint.x,ControlPoint.x) and SameValue(LastPoint.y,ControlPoint.y))) then begin
       if DoSubdivideCurvesIntoLines then begin
        AddCubicBezierCurveAsSubdividedLinesToPathSegmentArray(Contour^,[LastPoint,ControlPoint,OtherControlPoint,Point]);
       end else begin
        AddCubicBezierCurveAsSubdividedLinesToPathSegmentArray(Contour^,[LastPoint,ControlPoint,OtherControlPoint,Point]);
//      AddCubicBezierCurveAsSubdividedQuadraticBezierCurvesToPathSegmentArray(Contour^,[LastPoint,ControlPoint,OtherControlPoint,Point]);
       end;
      end;
      LastPoint:=Point;
     end;
     TpvVectorPathCommandType.Close:begin
      if assigned(Contour) then begin
       if not (SameValue(LastPoint.x,StartPoint.x) and SameValue(LastPoint.y,StartPoint.y)) then begin
        AddLineToPathSegmentArray(Contour^,[LastPoint,StartPoint]);
       end;
       SetLength(Contour^.PathSegments,Contour^.CountPathSegments);
      end;
      Contour:=nil;
     end;
    end;
   end;
  finally
   if assigned(Contour) then begin
    SetLength(Contour^.PathSegments,Contour^.CountPathSegments);
   end;
  end;
 finally
  SetLength(fShape.Contours,fShape.CountContours);
 end;
end;

procedure TpvSignedDistanceField2DGenerator.SplitPathSegmentIntoThreePartsInsideContour(var Contour:TpvSignedDistanceField2DPathContour;const BasePathSegmentIndex:TpvInt32);
var BasePathSegment:TpvSignedDistanceField2DPathSegment;
begin
 if (BasePathSegmentIndex>=0) and (BasePathSegmentIndex<Contour.CountPathSegments) then begin
  BasePathSegment:=Contour.PathSegments[BasePathSegmentIndex];
  if BasePathSegment.Type_ in [TpvSignedDistanceField2DPathSegmentType.Line,TpvSignedDistanceField2DPathSegmentType.QuadraticBezierCurve] then begin
   inc(Contour.CountPathSegments,2);
   if length(Contour.PathSegments)<=Contour.CountPathSegments then begin
    SetLength(Contour.PathSegments,Contour.CountPathSegments*2);
   end;
   Move(Contour.PathSegments[BasePathSegmentIndex+1],Contour.PathSegments[BasePathSegmentIndex+3],(Contour.CountPathSegments-(BasePathSegmentIndex+3))*SizeOf(TpvSignedDistanceField2DPathSegment));
   FillChar(Contour.PathSegments[BasePathSegmentIndex],SizeOf(TpvSignedDistanceField2DPathSegment)*3,#0);
  end else begin
   Assert(false);
  end;
  case BasePathSegment.Type_ of
   TpvSignedDistanceField2DPathSegmentType.Line:begin
    Contour.PathSegments[BasePathSegmentIndex+0].Type_:=TpvSignedDistanceField2DPathSegmentType.Line;
    Contour.PathSegments[BasePathSegmentIndex+0].Color:=BasePathSegment.Color;
    Contour.PathSegments[BasePathSegmentIndex+0].Points[0]:=BasePathSegment.Points[0];
    Contour.PathSegments[BasePathSegmentIndex+0].Points[1]:=DoublePrecisionPointLerp(BasePathSegment.Points[0],BasePathSegment.Points[1],1.0/3.0);
    Contour.PathSegments[BasePathSegmentIndex+1].Type_:=TpvSignedDistanceField2DPathSegmentType.Line;
    Contour.PathSegments[BasePathSegmentIndex+1].Color:=BasePathSegment.Color;
    Contour.PathSegments[BasePathSegmentIndex+1].Points[0]:=Contour.PathSegments[BasePathSegmentIndex+0].Points[1];
    Contour.PathSegments[BasePathSegmentIndex+1].Points[1]:=DoublePrecisionPointLerp(BasePathSegment.Points[0],BasePathSegment.Points[1],2.0/3.0);
    Contour.PathSegments[BasePathSegmentIndex+2].Type_:=TpvSignedDistanceField2DPathSegmentType.Line;
    Contour.PathSegments[BasePathSegmentIndex+2].Color:=BasePathSegment.Color;
    Contour.PathSegments[BasePathSegmentIndex+2].Points[0]:=Contour.PathSegments[BasePathSegmentIndex+1].Points[1];
    Contour.PathSegments[BasePathSegmentIndex+2].Points[1]:=BasePathSegment.Points[1];
   end;
   TpvSignedDistanceField2DPathSegmentType.QuadraticBezierCurve:begin
    Contour.PathSegments[BasePathSegmentIndex+0].Type_:=TpvSignedDistanceField2DPathSegmentType.QuadraticBezierCurve;
    Contour.PathSegments[BasePathSegmentIndex+0].Color:=BasePathSegment.Color;
    Contour.PathSegments[BasePathSegmentIndex+0].Points[0]:=BasePathSegment.Points[0];
    Contour.PathSegments[BasePathSegmentIndex+0].Points[1]:=DoublePrecisionPointLerp(BasePathSegment.Points[0],BasePathSegment.Points[1],1.0/3.0);
    Contour.PathSegments[BasePathSegmentIndex+0].Points[2]:=DoublePrecisionPointLerp(DoublePrecisionPointLerp(BasePathSegment.Points[0],BasePathSegment.Points[1],1.0/3.0),DoublePrecisionPointLerp(BasePathSegment.Points[1],BasePathSegment.Points[2],1.0/3.0),1.0/3.0);
    Contour.PathSegments[BasePathSegmentIndex+1].Type_:=TpvSignedDistanceField2DPathSegmentType.QuadraticBezierCurve;
    Contour.PathSegments[BasePathSegmentIndex+1].Color:=BasePathSegment.Color;
    Contour.PathSegments[BasePathSegmentIndex+1].Points[0]:=Contour.PathSegments[BasePathSegmentIndex+0].Points[2];
    Contour.PathSegments[BasePathSegmentIndex+1].Points[1]:=DoublePrecisionPointLerp(DoublePrecisionPointLerp(BasePathSegment.Points[0],BasePathSegment.Points[1],5.0/9.0),DoublePrecisionPointLerp(BasePathSegment.Points[1],BasePathSegment.Points[2],4.0/9.0),0.5);
    Contour.PathSegments[BasePathSegmentIndex+1].Points[2]:=DoublePrecisionPointLerp(DoublePrecisionPointLerp(BasePathSegment.Points[0],BasePathSegment.Points[1],2.0/3.0),DoublePrecisionPointLerp(BasePathSegment.Points[1],BasePathSegment.Points[2],2.0/3.0),2.0/3.0);
    Contour.PathSegments[BasePathSegmentIndex+2].Type_:=TpvSignedDistanceField2DPathSegmentType.QuadraticBezierCurve;
    Contour.PathSegments[BasePathSegmentIndex+2].Color:=BasePathSegment.Color;
    Contour.PathSegments[BasePathSegmentIndex+2].Points[0]:=Contour.PathSegments[BasePathSegmentIndex+1].Points[2];
    Contour.PathSegments[BasePathSegmentIndex+2].Points[1]:=DoublePrecisionPointLerp(BasePathSegment.Points[0],BasePathSegment.Points[1],2.0/3.0);
    Contour.PathSegments[BasePathSegmentIndex+2].Points[2]:=BasePathSegment.Points[2];
   end;
   else begin
    Assert(false);
   end;
  end;
  InitializePathSegment(Contour.PathSegments[BasePathSegmentIndex+0]);
  InitializePathSegment(Contour.PathSegments[BasePathSegmentIndex+1]);
  InitializePathSegment(Contour.PathSegments[BasePathSegmentIndex+2]);
 end;
end;

procedure TpvSignedDistanceField2DGenerator.SplitPathSegmentIntoThreePartsToContour(var Contour:TpvSignedDistanceField2DPathContour;const BasePathSegmentIndex:TpvInt32;const BasePathSegment:TpvSignedDistanceField2DPathSegment);
begin
 if (BasePathSegmentIndex>=0) and (BasePathSegmentIndex<Contour.CountPathSegments) then begin
  case BasePathSegment.Type_ of
   TpvSignedDistanceField2DPathSegmentType.Line:begin
    Contour.PathSegments[BasePathSegmentIndex+0].Type_:=TpvSignedDistanceField2DPathSegmentType.Line;
    Contour.PathSegments[BasePathSegmentIndex+0].Color:=BasePathSegment.Color;
    Contour.PathSegments[BasePathSegmentIndex+0].Points[0]:=BasePathSegment.Points[0];
    Contour.PathSegments[BasePathSegmentIndex+0].Points[1]:=DoublePrecisionPointLerp(BasePathSegment.Points[0],BasePathSegment.Points[1],1.0/3.0);
    Contour.PathSegments[BasePathSegmentIndex+1].Type_:=TpvSignedDistanceField2DPathSegmentType.Line;
    Contour.PathSegments[BasePathSegmentIndex+1].Color:=BasePathSegment.Color;
    Contour.PathSegments[BasePathSegmentIndex+1].Points[0]:=Contour.PathSegments[BasePathSegmentIndex+0].Points[1];
    Contour.PathSegments[BasePathSegmentIndex+1].Points[1]:=DoublePrecisionPointLerp(BasePathSegment.Points[0],BasePathSegment.Points[1],2.0/3.0);
    Contour.PathSegments[BasePathSegmentIndex+2].Type_:=TpvSignedDistanceField2DPathSegmentType.Line;
    Contour.PathSegments[BasePathSegmentIndex+2].Color:=BasePathSegment.Color;
    Contour.PathSegments[BasePathSegmentIndex+2].Points[0]:=Contour.PathSegments[BasePathSegmentIndex+1].Points[1];
    Contour.PathSegments[BasePathSegmentIndex+2].Points[1]:=BasePathSegment.Points[1];
   end;
   TpvSignedDistanceField2DPathSegmentType.QuadraticBezierCurve:begin
    Contour.PathSegments[BasePathSegmentIndex+0].Type_:=TpvSignedDistanceField2DPathSegmentType.QuadraticBezierCurve;
    Contour.PathSegments[BasePathSegmentIndex+0].Color:=BasePathSegment.Color;
    Contour.PathSegments[BasePathSegmentIndex+0].Points[0]:=BasePathSegment.Points[0];
    Contour.PathSegments[BasePathSegmentIndex+0].Points[1]:=DoublePrecisionPointLerp(BasePathSegment.Points[0],BasePathSegment.Points[1],1.0/3.0);
    Contour.PathSegments[BasePathSegmentIndex+0].Points[2]:=DoublePrecisionPointLerp(DoublePrecisionPointLerp(BasePathSegment.Points[0],BasePathSegment.Points[1],1.0/3.0),DoublePrecisionPointLerp(BasePathSegment.Points[1],BasePathSegment.Points[2],1.0/3.0),1.0/3.0);
    Contour.PathSegments[BasePathSegmentIndex+1].Type_:=TpvSignedDistanceField2DPathSegmentType.QuadraticBezierCurve;
    Contour.PathSegments[BasePathSegmentIndex+1].Color:=BasePathSegment.Color;
    Contour.PathSegments[BasePathSegmentIndex+1].Points[0]:=Contour.PathSegments[BasePathSegmentIndex+0].Points[2];
    Contour.PathSegments[BasePathSegmentIndex+1].Points[1]:=DoublePrecisionPointLerp(DoublePrecisionPointLerp(BasePathSegment.Points[0],BasePathSegment.Points[1],5.0/9.0),DoublePrecisionPointLerp(BasePathSegment.Points[1],BasePathSegment.Points[2],4.0/9.0),0.5);
    Contour.PathSegments[BasePathSegmentIndex+1].Points[2]:=DoublePrecisionPointLerp(DoublePrecisionPointLerp(BasePathSegment.Points[0],BasePathSegment.Points[1],2.0/3.0),DoublePrecisionPointLerp(BasePathSegment.Points[1],BasePathSegment.Points[2],2.0/3.0),2.0/3.0);
    Contour.PathSegments[BasePathSegmentIndex+2].Type_:=TpvSignedDistanceField2DPathSegmentType.QuadraticBezierCurve;
    Contour.PathSegments[BasePathSegmentIndex+2].Color:=BasePathSegment.Color;
    Contour.PathSegments[BasePathSegmentIndex+2].Points[0]:=Contour.PathSegments[BasePathSegmentIndex+1].Points[2];
    Contour.PathSegments[BasePathSegmentIndex+2].Points[1]:=DoublePrecisionPointLerp(BasePathSegment.Points[0],BasePathSegment.Points[1],2.0/3.0);
    Contour.PathSegments[BasePathSegmentIndex+2].Points[2]:=BasePathSegment.Points[2];
   end;
   else begin
    Assert(false);
   end;
  end;
  InitializePathSegment(Contour.PathSegments[BasePathSegmentIndex+0]);
  InitializePathSegment(Contour.PathSegments[BasePathSegmentIndex+1]);
  InitializePathSegment(Contour.PathSegments[BasePathSegmentIndex+2]);
 end;
end;

procedure TpvSignedDistanceField2DGenerator.NormalizeShape;
var ContourIndex:TpvInt32;
    Contour:PpvSignedDistanceField2DPathContour;
begin
 for ContourIndex:=0 to fShape.CountContours-1 do begin
  Contour:=@fShape.Contours[ContourIndex];
  if Contour^.CountPathSegments=1 then begin
   try
    SplitPathSegmentIntoThreePartsInsideContour(Contour^,0);
   finally
    SetLength(Contour^.PathSegments,Contour^.CountPathSegments);
   end;
  end;
 end;
end;

procedure TpvSignedDistanceField2DGenerator.PathSegmentColorizeShape;
const AngleThreshold=3.0;
      EdgeThreshold=1.00000001;
type PCorner=^TCorner;
     TCorner=TpvInt32;
     TCorners=array of TCorner;
var ContourIndex,PathSegmentIndex,CountCorners,CornerIndex,SplineIndex,StartIndex,
    OtherPathSegmentIndex:TpvInt32;
    Seed:TpvUInt64;
    Contour:PpvSignedDistanceField2DPathContour;
    PathSegment:PpvSignedDistanceField2DPathSegment;
    Corners:TCorners;
    CurrentDirection,PreviousDirection,a,b:TpvSignedDistanceField2DDoublePrecisionPoint;
    CrossThreshold:TpvDouble;
    Color,InitialColor:TpvSignedDistanceField2DPathSegmentColor;
    Colors:array[0..2] of TpvSignedDistanceField2DPathSegmentColor;
    PathSegments:TpvSignedDistanceField2DPathSegments;
 procedure SwitchColor(var Color:TpvSignedDistanceField2DPathSegmentColor;const BannedColor:TpvSignedDistanceField2DPathSegmentColor=TpvSignedDistanceField2DPathSegmentColor.Black);
 const StartColors:array[0..2] of TpvSignedDistanceField2DPathSegmentColor=(TpvSignedDistanceField2DPathSegmentColor.Cyan,TpvSignedDistanceField2DPathSegmentColor.Magenta,TpvSignedDistanceField2DPathSegmentColor.Yellow);
 var CombinedColor:TpvSignedDistanceField2DPathSegmentColor;
     Shifted:TpvUInt64;
 begin
  CombinedColor:=TpvSignedDistanceField2DPathSegmentColor(TpvInt32(TpvInt32(Color) and TpvInt32(BannedColor)));
  if CombinedColor in [TpvSignedDistanceField2DPathSegmentColor.Red,TpvSignedDistanceField2DPathSegmentColor.Green,TpvSignedDistanceField2DPathSegmentColor.Blue] then begin
   Color:=TpvSignedDistanceField2DPathSegmentColor(TpvInt32(TpvInt32(CombinedColor) xor TpvInt32(TpvSignedDistanceField2DPathSegmentColor(TpvSignedDistanceField2DPathSegmentColor.White))));
  end else if CombinedColor in [TpvSignedDistanceField2DPathSegmentColor.Black,TpvSignedDistanceField2DPathSegmentColor.White] then begin
   Color:=StartColors[Seed mod 3];
   Seed:=Seed div 3;
  end else begin
   Shifted:=TpvInt32(Color) shl (1+(Seed and 1));
   Color:=TpvSignedDistanceField2DPathSegmentColor(TpvInt32((Shifted or (Shifted shr 3)) and TpvInt32(TpvSignedDistanceField2DPathSegmentColor(TpvSignedDistanceField2DPathSegmentColor.White))));
   Seed:=Seed shr 1;
  end;
 end;
begin

 Seed:=$7ffffffffffffff;

 CrossThreshold:=sin(AngleThreshold);

 for ContourIndex:=0 to fShape.CountContours-1 do begin

  Contour:=@fShape.Contours[ContourIndex];
  try

   Corners:=nil;
   CountCorners:=0;
   try

    if Contour^.CountPathSegments>0 then begin

     PreviousDirection:=PathSegmentDirection(Contour^.PathSegments[Contour^.CountPathSegments-1],1);

     for PathSegmentIndex:=0 to Contour^.CountPathSegments-1 do begin

      PathSegment:=@Contour^.PathSegments[PathSegmentIndex];

      CurrentDirection:=PathSegmentDirection(PathSegment^,0);

      a:=DoublePrecisionPointNormalize(PreviousDirection);
      b:=DoublePrecisionPointNormalize(CurrentDirection);

      if (((a.x*b.x)+(a.y*b.y))<=0.0) or (abs((a.x*b.y)-(a.y*b.x))>CrossThreshold) then begin

       if length(Corners)<(CountCorners+1) then begin
        SetLength(Corners,(CountCorners+1)*2);
       end;
       Corners[CountCorners]:=PathSegmentIndex;
       inc(CountCorners);

      end;

      PreviousDirection:=PathSegmentDirection(PathSegment^,1);

     end;

    end;

    case CountCorners of
     0:begin
      for PathSegmentIndex:=0 to Contour^.CountPathSegments-1 do begin
       PathSegment:=@Contour^.PathSegments[PathSegmentIndex];
       PathSegment^.Color:=TpvSignedDistanceField2DPathSegmentColor.White;
      end;
     end;
     1:begin
      Colors[0]:=TpvSignedDistanceField2DPathSegmentColor.White;
      Colors[1]:=TpvSignedDistanceField2DPathSegmentColor.White;
      SwitchColor(Colors[0]);
      Colors[2]:=Colors[0];
      SwitchColor(Colors[2]);
      CornerIndex:=Corners[0];
      if Contour^.CountPathSegments>2 then begin
       for PathSegmentIndex:=0 to Contour^.CountPathSegments-1 do begin
        PathSegment:=@Contour^.PathSegments[CornerIndex];
        PathSegment^.Color:=Colors[abs((trunc(((3+((2.875*PathSegmentIndex)/(Contour^.CountPathSegments-1)))-1.4375)+0.5)-3)+1) mod 3];
        inc(CornerIndex);
        if CornerIndex>=Contour^.CountPathSegments then begin
         CornerIndex:=0;
        end;
       end;
      end else if Contour^.CountPathSegments=2 then begin
       PathSegments:=copy(Contour^.PathSegments,0,Contour^.CountPathSegments);
       try
        SetLength(Contour^.PathSegments,6);
        try
         Contour^.CountPathSegments:=6;
         SplitPathSegmentIntoThreePartsToContour(Contour^,CornerIndex*3,PathSegments[0]);
         SplitPathSegmentIntoThreePartsToContour(Contour^,3-(CornerIndex*3),PathSegments[1]);
         Contour^.PathSegments[0].Color:=Colors[0];
         Contour^.PathSegments[1].Color:=Colors[0];
         Contour^.PathSegments[2].Color:=Colors[1];
         Contour^.PathSegments[3].Color:=Colors[1];
         Contour^.PathSegments[4].Color:=Colors[2];
         Contour^.PathSegments[5].Color:=Colors[2];
        finally
         SetLength(Contour^.PathSegments,Contour^.CountPathSegments);
        end;
       finally
        PathSegments:=nil;
       end;
      end else if Contour^.CountPathSegments=1 then begin
       PathSegments:=copy(Contour^.PathSegments,0,Contour^.CountPathSegments);
       try
        SetLength(Contour^.PathSegments,3);
        try
         Contour^.CountPathSegments:=3;
         SplitPathSegmentIntoThreePartsToContour(Contour^,0,PathSegments[0]);
         Contour^.PathSegments[0].Color:=Colors[0];
         Contour^.PathSegments[1].Color:=Colors[1];
         Contour^.PathSegments[2].Color:=Colors[2];
        finally
         SetLength(Contour^.PathSegments,Contour^.CountPathSegments);
        end;
       finally
        PathSegments:=nil;
       end;
      end;
     end;
     else begin
      SplineIndex:=0;
      StartIndex:=Corners[0];
      Color:=TpvSignedDistanceField2DPathSegmentColor.White;
      SwitchColor(Color);
      InitialColor:=Color;
      for PathSegmentIndex:=0 to Contour^.CountPathSegments-1 do begin
       OtherPathSegmentIndex:=StartIndex+PathSegmentIndex;
       if OtherPathSegmentIndex>=Contour^.CountPathSegments then begin
        dec(OtherPathSegmentIndex,Contour^.CountPathSegments);
       end;
       if ((SplineIndex+1)<CountCorners) and (Corners[SplineIndex+1]=OtherPathSegmentIndex) then begin
        inc(SplineIndex);
        SwitchColor(Color,TpvSignedDistanceField2DPathSegmentColor(TpvInt32(IfThen(SplineIndex=(CountCorners-1),TpvInt32(InitialColor),TpvInt32(TpvSignedDistanceField2DPathSegmentColor(TpvSignedDistanceField2DPathSegmentColor.Black))))));
       end;
       Contour^.PathSegments[OtherPathSegmentIndex].Color:=Color;
      end;
     end;
    end;

   finally
    Corners:=nil;
   end;

  finally
   SetLength(Contour^.PathSegments,Contour^.CountPathSegments);
  end;

 end;

end;

function TpvSignedDistanceField2DGenerator.GetLineNonClippedTime(const p,p0,p1:TpvSignedDistanceField2DDoublePrecisionPoint):TpvDouble;
var pAP,pAB:TpvSignedDistanceField2DDoublePrecisionPoint;
begin
 pAP.x:=p.x-p0.x;
 pAP.y:=p.y-p0.y;
 pAB.x:=p1.x-p0.x;
 pAB.y:=p1.y-p0.y;
 result:=((pAP.x*pAB.x)+(pAP.y*pAB.y))/(sqr(pAB.x)+sqr(pAB.y));
end;

function TpvSignedDistanceField2DGenerator.GetQuadraticBezierCurveNonClippedTime(const p,p0,p1,p2:TpvSignedDistanceField2DDoublePrecisionPoint):TpvDouble;
var b0,b1,b2,d21,d10,d20,gf,pp,d0p:TpvSignedDistanceField2DDoublePrecisionPoint;
    a,b,d,f,ap,bp,v,c:TpvDouble;
begin
 b0.x:=p0.x-p.x;
 b0.y:=p0.y-p.y;
 b1.x:=p1.x-p.x;
 b1.y:=p1.y-p.y;
 b2.x:=p2.x-p.x;
 b2.y:=p2.y-p.y;
 a:=((b0.x*b2.y)-(b0.y*b2.x))*2.0;
 b:=((b1.x*b0.y)-(b1.y*b0.x))*2.0;
 d:=((b2.x*b1.y)-(b2.y*b1.x))*2.0;
 c:=(2.0*a)+b+d;
 if IsZero(c) then begin
  result:=GetLineNonClippedTime(p,p0,p2);
 end else begin
  f:=(b*d)-sqr(a);
  d21.x:=b2.x-b1.x;
  d21.y:=b2.y-b1.y;
  d10.x:=b1.x-b0.x;
  d10.y:=b1.y-b0.y;
  d20.x:=b2.x-b0.x;
  d20.y:=b2.y-b0.y;
  gf.x:=((d21.y*b)+(d10.y*d)+(d20.y*a))*2.0;
  gf.y:=((d21.x*b)+(d10.x*d)+(d20.x*a))*(-2.0);
  v:=-(f/(sqr(gf.x)+sqr(gf.y)));
  pp.x:=gf.x*v;
  pp.y:=gf.y*v;
  d0p.x:=b0.x-pp.x;
  d0p.y:=b0.y-pp.y;
  ap:=(d0p.x*d20.y)-(d0p.y*d20.x);
  bp:=((d10.x*d0p.y)-(d10.y*d0p.x))*2.0;
  result:=(ap+bp)/c;
 end;
end;

function TpvSignedDistanceField2DGenerator.GetNonClampedSignedLineDistance(const p,p0,p1:TpvSignedDistanceField2DDoublePrecisionPoint):TpvDouble;
begin
 result:=((p.x*(p0.y-p1.y))+(p0.x*(p1.y-p.y))+(p1.x*(p.y-p0.y)))/sqrt(sqr(p1.x-p0.x)+sqr(p1.y-p0.y));
end;

procedure TpvSignedDistanceField2DGenerator.CalculateDistanceFieldDataLineRange(const FromY,ToY:TpvInt32);
var ContourIndex,PathSegmentIndex,x0,y0,x1,y1,x,y,PixelIndex,Dilation,DeltaWindingScore:TpvInt32;
    Contour:PpvSignedDistanceField2DPathContour;
    PathSegment:PpvSignedDistanceField2DPathSegment;
    PathSegmentBoundingBox:TpvSignedDistanceField2DBoundingBox;
    PreviousPathSegmentSide,PathSegmentSide:TpvSignedDistanceField2DPathSegmentSide;
    RowData:TpvSignedDistanceField2DRowData;
    DistanceFieldDataItem:PpvSignedDistanceField2DDataItem;
    PointLeft,PointRight,Point,p0,p1,Direction,OriginPointDifference:TpvSignedDistanceField2DDoublePrecisionPoint;
    pX,pY,CurrentSquaredDistance,CurrentSquaredPseudoDistance,Time,Value:TpvDouble;
begin
 RowData.QuadraticXDirection:=0;
 for ContourIndex:=0 to fShape.CountContours-1 do begin
  Contour:=@fShape.Contours[ContourIndex];
  for PathSegmentIndex:=0 to Contour^.CountPathSegments-1 do begin
   PathSegment:=@Contour^.PathSegments[PathSegmentIndex];
   PathSegmentBoundingBox.Min.x:=PathSegment.BoundingBox.Min.x-DistanceField2DPadValue;
   PathSegmentBoundingBox.Min.y:=PathSegment.BoundingBox.Min.y-DistanceField2DPadValue;
   PathSegmentBoundingBox.Max.x:=PathSegment.BoundingBox.Max.x+DistanceField2DPadValue;
   PathSegmentBoundingBox.Max.y:=PathSegment.BoundingBox.Max.y+DistanceField2DPadValue;
   x0:=Clamp(Trunc(Floor(PathSegmentBoundingBox.Min.x)),0,fDistanceField.Width-1);
   y0:=Clamp(Trunc(Floor(PathSegmentBoundingBox.Min.y)),0,fDistanceField.Height-1);
   x1:=Clamp(Trunc(Ceil(PathSegmentBoundingBox.Max.x)),0,fDistanceField.Width-1);
   y1:=Clamp(Trunc(Ceil(PathSegmentBoundingBox.Max.y)),0,fDistanceField.Height-1);
{  x0:=0;
   y0:=0;
   x1:=DistanceField.Width-1;
   y1:=DistanceField.Height-1;}
   for y:=Max(FromY,y0) to Min(ToY,y1) do begin
    PreviousPathSegmentSide:=TpvSignedDistanceField2DPathSegmentSide.None;
    pY:=y+0.5;
    PointLeft.x:=x0;
    PointLeft.y:=pY;
    PointRight.x:=x1;
    PointRight.y:=pY;
    if BetweenClosedOpen(pY,PathSegment.BoundingBox.Min.y,PathSegment.BoundingBox.Max.y) then begin
     PrecomputationForRow(RowData,PathSegment^,PointLeft,PointRight);
    end;
    for x:=x0 to x1 do begin
     PixelIndex:=(y*fDistanceField.Width)+x;
     pX:=x+0.5;
     Point.x:=pX;
     Point.y:=pY;
     DistanceFieldDataItem:=@fDistanceFieldData[PixelIndex];
     Dilation:=Clamp(Floor(sqrt(Max(1,DistanceFieldDataItem^.SquaredDistance))+0.5),1,DistanceField2DPadValue);
     PathSegmentBoundingBox.Min.x:=Floor(PathSegment.BoundingBox.Min.x)-DistanceField2DPadValue;
     PathSegmentBoundingBox.Min.y:=Floor(PathSegment.BoundingBox.Min.y)-DistanceField2DPadValue;
     PathSegmentBoundingBox.Max.x:=Ceil(PathSegment.BoundingBox.Max.x)+DistanceField2DPadValue;
     PathSegmentBoundingBox.Max.y:=Ceil(PathSegment.BoundingBox.Max.y)+DistanceField2DPadValue;
     if (Dilation<>DistanceField2DPadValue) and not
        (((x>=PathSegmentBoundingBox.Min.x) and (x<=PathSegmentBoundingBox.Max.x)) and
         ((y>=PathSegmentBoundingBox.Min.y) and (y<=PathSegmentBoundingBox.Max.y))) then begin
      continue;
     end else begin
      PathSegmentSide:=TpvSignedDistanceField2DPathSegmentSide.None;
      CurrentSquaredDistance:=DistanceToPathSegment(Point,PathSegment^,RowData,PathSegmentSide);
      CurrentSquaredPseudoDistance:=CurrentSquaredDistance;
(**)  if fMultiChannel then begin
       case PathSegment^.Type_ of
        TpvSignedDistanceField2DPathSegmentType.Line:begin
         Time:=GetLineNonClippedTime(Point,PathSegment^.Points[0],PathSegment^.Points[1]);
        end;
        TpvSignedDistanceField2DPathSegmentType.QuadraticBezierCurve:begin
         Time:=GetQuadraticBezierCurveNonClippedTime(Point,PathSegment^.Points[0],PathSegment^.Points[1],PathSegment^.Points[2]);
        end;
        else begin
         Time:=0.5;
        end;
       end;
       if Time<=0.0 then begin
        p0:=PathSegmentCornerPoint(PathSegment^,0,0)^;
        p1:=PathSegmentCornerPoint(PathSegment^,0,1)^;
        Direction:=DoublePrecisionPointNormalize(DoublePrecisionPointSub(p1,p0));
        OriginPointDifference:=DoublePrecisionPointSub(Point,p0);
        if DoublePrecisionPointDotProduct(OriginPointDifference,Direction)<0.0 then begin
         Value:=DoublePrecisionPointCrossProduct(OriginPointDifference,Direction);
//         Value:=GetNonClampedSignedLineDistance(Point,p0,p1);
         if abs(Value)<=abs(CurrentSquaredPseudoDistance) then begin
          CurrentSquaredPseudoDistance:=abs(Value);
         end;
        end;
{       Value:=GetNonClampedSignedLineDistance(Point,PathSegmentCornerPoint(PathSegment^,0,0)^,PathSegmentCornerPoint(PathSegment^,0,1)^);
        if Value<0.0 then begin
         Value:=sqr(Value);
         if abs(Value)<=abs(CurrentSquaredPseudoDistance) then begin
          CurrentSquaredPseudoDistance:=abs(Value);
         end;
        end;}
       end else if Time>=1.0 then begin
        p0:=PathSegmentCornerPoint(PathSegment^,1,0)^;
        p1:=PathSegmentCornerPoint(PathSegment^,1,1)^;
        Direction:=DoublePrecisionPointNormalize(DoublePrecisionPointSub(p1,p0));
        OriginPointDifference:=DoublePrecisionPointSub(Point,p1);
        if DoublePrecisionPointDotProduct(OriginPointDifference,Direction)>0.0 then begin
         Value:=DoublePrecisionPointCrossProduct(OriginPointDifference,Direction);
//         Value:=GetNonClampedSignedLineDistance(Point,p0,p1);
         if abs(Value)<=abs(CurrentSquaredPseudoDistance) then begin
          CurrentSquaredPseudoDistance:=abs(Value);
         end;
        end;
{       Value:=GetNonClampedSignedLineDistance(Point,PathSegmentCornerPoint(PathSegment^,1,0)^,PathSegmentCornerPoint(PathSegment^,1,1)^);
        if Value>0.0 then begin
         Value:=sqr(Value);
         if abs(Value)<=abs(CurrentSquaredPseudoDistance) then begin
          CurrentSquaredPseudoDistance:=abs(Value);
         end;
        end;}
       end;
      end;(**)
      if (PreviousPathSegmentSide=TpvSignedDistanceField2DPathSegmentSide.Left) and (PathSegmentSide=TpvSignedDistanceField2DPathSegmentSide.Right) then begin
       DeltaWindingScore:=-1;
      end else if (PreviousPathSegmentSide=TpvSignedDistanceField2DPathSegmentSide.Right) and (PathSegmentSide=TpvSignedDistanceField2DPathSegmentSide.Left) then begin
       DeltaWindingScore:=1;
      end else begin
       DeltaWindingScore:=0;
      end;
      PreviousPathSegmentSide:=PathSegmentSide;
      if CurrentSquaredDistance<DistanceFieldDataItem^.SquaredDistance then begin
       DistanceFieldDataItem^.SquaredDistance:=CurrentSquaredDistance;
      end;
      if fMultiChannel then begin
       if (((TpvInt32(PathSegment^.Color) and TpvInt32(TpvSignedDistanceField2DPathSegmentColor(TpvSignedDistanceField2DPathSegmentColor.Red)))<>0)) and
          (CurrentSquaredDistance<DistanceFieldDataItem^.SquaredDistanceR) then begin
        DistanceFieldDataItem^.SquaredDistanceR:=CurrentSquaredDistance;
        DistanceFieldDataItem^.PseudoSquaredDistanceR:=CurrentSquaredPseudoDistance;
       end;
       if (((TpvInt32(PathSegment^.Color) and TpvInt32(TpvSignedDistanceField2DPathSegmentColor(TpvSignedDistanceField2DPathSegmentColor.Green)))<>0)) and
          (CurrentSquaredDistance<DistanceFieldDataItem^.SquaredDistanceG) then begin
        DistanceFieldDataItem^.SquaredDistanceG:=CurrentSquaredDistance;
        DistanceFieldDataItem^.PseudoSquaredDistanceG:=CurrentSquaredPseudoDistance;
       end;
       if (((TpvInt32(PathSegment^.Color) and TpvInt32(TpvSignedDistanceField2DPathSegmentColor(TpvSignedDistanceField2DPathSegmentColor.Blue)))<>0)) and
          (CurrentSquaredDistance<DistanceFieldDataItem^.SquaredDistanceB) then begin
        DistanceFieldDataItem^.SquaredDistanceB:=CurrentSquaredDistance;
        DistanceFieldDataItem^.PseudoSquaredDistanceB:=CurrentSquaredPseudoDistance;
       end;
      end;
      inc(DistanceFieldDataItem^.DeltaWindingScore,DeltaWindingScore);
     end;
    end;
   end;
  end;
 end;
end;

procedure TpvSignedDistanceField2DGenerator.CalculateDistanceFieldDataLineRangeParallelForJobFunction(const Job:PPasMPJob;const ThreadIndex:TPasMPInt32;const Data:TpvPointer;const FromIndex,ToIndex:TPasMPNativeInt);
begin
 CalculateDistanceFieldDataLineRange(FromIndex,ToIndex);
end;

function TpvSignedDistanceField2DGenerator.PackDistanceFieldValue(Distance:TpvDouble):TpvUInt8;
begin
 result:=Clamp(Round((Distance*(128.0/DistanceField2DMagnitudeValue))+128.0),0,255);
end;

function TpvSignedDistanceField2DGenerator.PackPseudoDistanceFieldValue(Distance:TpvDouble):TpvUInt8;
begin
 result:=Clamp(Round((Distance*(128.0/DistanceField2DMagnitudeValue))+128.0),0,255);
end;

procedure TpvSignedDistanceField2DGenerator.ConvertToPointInPolygonPathSegments;
var ContourIndex,PathSegmentIndex,CountPathSegments:TpvInt32;
    Contour:PpvSignedDistanceField2DPathContour;
    PathSegment:PpvSignedDistanceField2DPathSegment;
    StartPoint,LastPoint:TpvSignedDistanceField2DDoublePrecisionPoint;
 procedure AddPathSegment(const p0,p1:TpvSignedDistanceField2DDoublePrecisionPoint);
 var Index:TpvInt32;
     PointInPolygonPathSegment:PpvSignedDistanceField2DPointInPolygonPathSegment;
 begin
  if not (SameValue(p0.x,p1.x) and SameValue(p0.y,p1.y)) then begin
   Index:=CountPathSegments;
   inc(CountPathSegments);
   if length(fPointInPolygonPathSegments)<CountPathSegments then begin
    SetLength(fPointInPolygonPathSegments,CountPathSegments*2);
   end;
   PointInPolygonPathSegment:=@fPointInPolygonPathSegments[Index];
   PointInPolygonPathSegment^.Points[0]:=p0;
   PointInPolygonPathSegment^.Points[1]:=p1;
  end;
 end;
 procedure AddQuadraticBezierCurveAsSubdividedLinesToPathSegmentArray(const p0,p1,p2:TpvSignedDistanceField2DDoublePrecisionPoint);
 var LastPoint:TpvSignedDistanceField2DDoublePrecisionPoint;
  procedure LineToPointAt(const Point:TpvSignedDistanceField2DDoublePrecisionPoint);
  begin
   AddPathSegment(LastPoint,Point);
   LastPoint:=Point;
  end;
  procedure Recursive(const x1,y1,x2,y2,x3,y3:TpvDouble;const Level:TpvInt32);
  var x12,y12,x23,y23,x123,y123,dx,dy:TpvDouble;
      Point:TpvSignedDistanceField2DDoublePrecisionPoint;
  begin
   x12:=(x1+x2)*0.5;
   y12:=(y1+y2)*0.5;
   x23:=(x2+x3)*0.5;
   y23:=(y2+y3)*0.5;
   x123:=(x12+x23)*0.5;
   y123:=(y12+y23)*0.5;
   dx:=x3-x1;
   dy:=y3-y1;
   if (Level>CurveRecursionLimit) or
      ((Level>0) and
       (sqr(((x2-x3)*dy)-((y2-y3)*dx))<((sqr(dx)+sqr(dy))*CurveTessellationToleranceSquared))) then begin
    Point.x:=x3;
    Point.y:=y3;
    LineToPointAt(Point);
   end else begin
    Recursive(x1,y1,x12,y12,x123,y123,Level+1);
    Recursive(x123,y123,x23,y23,x3,y3,Level+1);
   end;
  end;
 begin
  LastPoint:=p0;
  Recursive(p0.x,p0.y,p1.x,p1.y,p2.x,p2.y,0);
  LineToPointAt(p2);
 end;
begin
 fPointInPolygonPathSegments:=nil;
 CountPathSegments:=0;
 try
  for ContourIndex:=0 to fShape.CountContours-1 do begin
   Contour:=@fShape.Contours[ContourIndex];
   if Contour^.CountPathSegments>0 then begin
    StartPoint.x:=0.0;
    StartPoint.y:=0.0;
    LastPoint.x:=0.0;
    LastPoint.y:=0.0;
    for PathSegmentIndex:=0 to Contour^.CountPathSegments-1 do begin
     PathSegment:=@Contour^.PathSegments[PathSegmentIndex];
     case PathSegment^.Type_ of
      TpvSignedDistanceField2DPathSegmentType.Line:begin
       if PathSegmentIndex=0 then begin
        StartPoint:=PathSegment^.Points[0];
       end;
       LastPoint:=PathSegment^.Points[1];
       AddPathSegment(PathSegment^.Points[0],PathSegment^.Points[1]);
      end;
      TpvSignedDistanceField2DPathSegmentType.QuadraticBezierCurve:begin
       if PathSegmentIndex=0 then begin
        StartPoint:=PathSegment^.Points[0];
       end;
       LastPoint:=PathSegment^.Points[2];
       AddQuadraticBezierCurveAsSubdividedLinesToPathSegmentArray(PathSegment^.Points[0],PathSegment^.Points[1],PathSegment^.Points[2]);
      end;
     end;
    end;
    if not (SameValue(LastPoint.x,StartPoint.x) and SameValue(LastPoint.y,StartPoint.y)) then begin
     AddPathSegment(LastPoint,StartPoint);
    end;
   end;
  end;
 finally
  SetLength(fPointInPolygonPathSegments,CountPathSegments);
 end;
end;

function TpvSignedDistanceField2DGenerator.GetWindingNumberAtPointInPolygon(const Point:TpvSignedDistanceField2DDoublePrecisionPoint):TpvInt32;
var Index,CaseIndex:TpvInt32;
    PointInPolygonPathSegment:PpvSignedDistanceField2DPointInPolygonPathSegment;
    x0,y0,x1,y1:TpvDouble;
begin
 result:=0;
 for Index:=0 to length(fPointInPolygonPathSegments)-1 do begin
  PointInPolygonPathSegment:=@fPointInPolygonPathSegments[Index];
  if SameValue(PointInPolygonPathSegment^.Points[0].x,PointInPolygonPathSegment^.Points[1].x) and
     SameValue(PointInPolygonPathSegment^.Points[0].y,PointInPolygonPathSegment^.Points[1].y) then begin
   continue;
  end;
  y0:=PointInPolygonPathSegment^.Points[0].y-Point.y;
  y1:=PointInPolygonPathSegment^.Points[1].y-Point.y;
  if y0<0.0 then begin
   CaseIndex:=0;
  end else if y0>0.0 then begin
   CaseIndex:=2;
  end else begin
   CaseIndex:=1;
  end;
  if y1<0.0 then begin
   inc(CaseIndex,0);
  end else if y1>0.0 then begin
   inc(CaseIndex,6);
  end else begin
   inc(CaseIndex,3);
  end;
  if CaseIndex in [1,2,3,6] then begin
   x0:=PointInPolygonPathSegment^.Points[0].x-Point.x;
   x1:=PointInPolygonPathSegment^.Points[1].x-Point.x;
   if not (((x0>0.0) and (x1>0.0)) or ((not ((x0<=0.0) and (x1<=0.0))) and ((x0-(y0*((x1-x0)/(y1-y0))))>0.0))) then begin
    if CaseIndex in [1,2] then begin
     inc(result);
    end else begin
     dec(result);
    end;
   end;
  end;
 end;
end;

function TpvSignedDistanceField2DGenerator.GenerateDistanceFieldPicture(const DistanceFieldData:TpvSignedDistanceField2DData;const Width,Height,TryIteration:TpvInt32):boolean;
var x,y,PixelIndex,DistanceFieldSign,WindingNumber,Value:TpvInt32;
    DistanceFieldDataItem:PpvSignedDistanceField2DDataItem;
    DistanceFieldPixel:PpvSignedDistanceField2DPixel;
    p:TpvSignedDistanceField2DDoublePrecisionPoint;
begin

 result:=true;

 PixelIndex:=0;
 for y:=0 to Height-1 do begin
  WindingNumber:=0;
  for x:=0 to Width-1 do begin
   DistanceFieldDataItem:=@DistanceFieldData[PixelIndex];
   if TryIteration=2 then begin
    p.x:=x+0.5;
    p.y:=y+0.5;
    WindingNumber:=GetWindingNumberAtPointInPolygon(p);
   end else begin
    inc(WindingNumber,DistanceFieldDataItem^.DeltaWindingScore);
    if (x=(Width-1)) and (WindingNumber<>0) then begin
     result:=false;
     break;
    end;
   end;
   case fVectorPath.FillRule of
    TpvVectorPathFillRule.NonZero:begin
     if WindingNumber<>0 then begin
      DistanceFieldSign:=1;
     end else begin
      DistanceFieldSign:=-1;
     end;
    end;
    else {TpvVectorPathFillRule.EvenOdd:}begin
     if (WindingNumber and 1)<>0 then begin
      DistanceFieldSign:=1;
     end else begin
      DistanceFieldSign:=-1;
     end;
    end;
   end;
   DistanceFieldPixel:=@fDistanceField^.Pixels[PixelIndex];
   if fMultiChannel then begin
    DistanceFieldPixel^.r:=PackPseudoDistanceFieldValue(sqrt(DistanceFieldDataItem^.PseudoSquaredDistanceR)*DistanceFieldSign);
    DistanceFieldPixel^.g:=PackPseudoDistanceFieldValue(sqrt(DistanceFieldDataItem^.PseudoSquaredDistanceG)*DistanceFieldSign);
    DistanceFieldPixel^.b:=PackPseudoDistanceFieldValue(sqrt(DistanceFieldDataItem^.PseudoSquaredDistanceB)*DistanceFieldSign);
    DistanceFieldPixel^.a:=PackDistanceFieldValue(sqrt(DistanceFieldDataItem^.SquaredDistance)*DistanceFieldSign);
   end else begin
    Value:=PackDistanceFieldValue(sqrt(DistanceFieldDataItem^.SquaredDistance)*DistanceFieldSign);
    DistanceFieldPixel^.r:=Value;
    DistanceFieldPixel^.g:=Value;
    DistanceFieldPixel^.b:=Value;
    DistanceFieldPixel^.a:=Value;
   end;
   inc(PixelIndex);
  end;
  if not result then begin
   break;
  end;
 end;

end;

procedure TpvSignedDistanceField2DGenerator.Execute(var aDistanceField:TpvSignedDistanceField2D;const aVectorPath:TpvVectorPath;const aScale:TpvDouble=1.0;const aOffsetX:TpvDouble=0.0;const aOffsetY:TpvDouble=0.0;const aMultiChannel:boolean=false);
var TryIteration:TpvInt32;
    PasMPInstance:TPasMP;
begin

 PasMPInstance:=TPasMP.GetGlobalInstance;

 fDistanceField:=@aDistanceField;

 fVectorPath:=aVectorPath;

 fScale:=aScale;

 fOffsetX:=aOffsetX;

 fOffsetY:=aOffsetY;

 fMultiChannel:=aMultiChannel;

 try

  Initialize(fShape);
  try

   fDistanceFieldData:=nil;
   try

    SetLength(fDistanceFieldData,fDistanceField.Width*fDistanceField.Height);

    fPointInPolygonPathSegments:=nil;
    try

     for TryIteration:=0 to 2 do begin
      case TryIteration of
       0,1:begin
        InitializeDistances;
        ConvertShape(TryIteration in [1,2]);
        if fMultiChannel then begin
         NormalizeShape;
         PathSegmentColorizeShape;
         NormalizeShape;
        end;
       end;
       else {2:}begin
        InitializeDistances;
        ConvertShape(true);
        ConvertToPointInPolygonPathSegments;
       end;
      end;
      PasMPInstance.Invoke(PasMPInstance.ParallelFor(nil,0,fDistanceField.Height-1,CalculateDistanceFieldDataLineRangeParallelForJobFunction,1,10,nil,0));
      if GenerateDistanceFieldPicture(fDistanceFieldData,fDistanceField.Width,fDistanceField.Height,TryIteration) then begin
       break;
      end else begin
       // Try it again, after all quadratic bezier curves were subdivided into lines at the next try iteration
      end;
     end;

    finally
     fPointInPolygonPathSegments:=nil;
    end;

   finally
    fDistanceFieldData:=nil;
   end;

  finally
   Finalize(fShape);
  end;

 finally

  fDistanceField:=nil;

  fVectorPath:=nil;

 end;

end;

class procedure TpvSignedDistanceField2DGenerator.Generate(var aDistanceField:TpvSignedDistanceField2D;const aVectorPath:TpvVectorPath;const aScale:TpvDouble=1.0;const aOffsetX:TpvDouble=0.0;const aOffsetY:TpvDouble=0.0;const aMultiChannel:boolean=false);
var Generator:TpvSignedDistanceField2DGenerator;
begin
 Generator:=TpvSignedDistanceField2DGenerator.Create;
 try
  Generator.Execute(aDistanceField,aVectorPath,aScale,aOffsetX,aOffsetY,aMultiChannel);
 finally
  Generator.Free;
 end;
end;

end.
