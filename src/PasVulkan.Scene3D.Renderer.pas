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
unit PasVulkan.Scene3D.Renderer;
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

uses Classes,
     SysUtils,
     Math,
     PasMP,
     Vulkan,
     PasVulkan.Types,
     PasVulkan.Math,
     PasVulkan.Framework,
     PasVulkan.Application,
     PasVulkan.Resources,
     PasVulkan.FrameGraph,
     PasVulkan.TimerQuery,
     PasVulkan.Collections,
     PasVulkan.CircularDoublyLinkedList,
     PasVulkan.VirtualReality,
     PasVulkan.Scene3D,
     PasVulkan.Scene3D.Renderer.Globals,
     PasVulkan.Scene3D.Renderer.SheenELUTData,
     PasVulkan.Scene3D.Renderer.SMAAData,
     PasVulkan.Scene3D.Renderer.SkyCubeMap,
     PasVulkan.Scene3D.Renderer.SkyBox,
     PasVulkan.Scene3D.Renderer.MipmappedArray2DImage,
     PasVulkan.Scene3D.Renderer.Lambertian.EnvMapCubeMap,
     PasVulkan.Scene3D.Renderer.Charlie.BRDF,
     PasVulkan.Scene3D.Renderer.Charlie.EnvMapCubeMap,
     PasVulkan.Scene3D.Renderer.GGX.BRDF,
     PasVulkan.Scene3D.Renderer.GGX.EnvMapCubeMap;

type TpvScene3DRenderer=class;

     TpvScene3DRendererBaseObject=class;

     TpvScene3DRendererBaseObjects=class(TpvObjectGenericList<TpvScene3DRendererBaseObject>);

     TpvScene3DRendererBaseObjectCircularDoublyLinkedListNode=class(TpvCircularDoublyLinkedListNode<TpvScene3DRendererBaseObject>);

     { TpvScene3DRendererBaseObject }
     TpvScene3DRendererBaseObject=class
      private
       fParent:TpvScene3DRendererBaseObject;
       fRenderer:TpvScene3DRenderer;
       fChildrenLock:TPasMPCriticalSection;
       fChildren:TpvScene3DRendererBaseObjectCircularDoublyLinkedListNode;
       fOwnCircularDoublyLinkedListNode:TpvScene3DRendererBaseObjectCircularDoublyLinkedListNode;
      public
       constructor Create(const aParent:TpvScene3DRendererBaseObject); reintroduce;
       destructor Destroy; override;
       procedure AfterConstruction; override;
       procedure BeforeDestruction; override;
      published
       property Parent:TpvScene3DRendererBaseObject read fParent;
       property Renderer:TpvScene3DRenderer read fRenderer;
     end;

     { TpvScene3DRenderer }
     TpvScene3DRenderer=class(TpvScene3DRendererBaseObject)
      private
       fScene3D:TpvScene3D;
       fVulkanDevice:TpvVulkanDevice;
       fCountInFlightFrames:TpvSizeInt;
       fAntialiasingMode:TpvScene3DRendererAntialiasingMode;
       fShadowMode:TpvScene3DRendererShadowMode;
       fTransparencyMode:TpvScene3DRendererTransparencyMode;
       fMaxMSAA:TpvInt32;
       fMaxShadowMSAA:TpvInt32;
       fShadowMapSize:TpvInt32;
       fBufferDeviceAddress:boolean;
       fMeshFragTypeName:TpvUTF8String;
       fMeshFragShadowTypeName:TpvUTF8String;
       fOptimizedNonAlphaFormat:TVkFormat;
       fUseDepthPrepass:boolean;
       fUseDemote:boolean;
       fUseNoDiscard:boolean;
       fUseOITAlphaTest:boolean;
       fShadowMapSampleCountFlagBits:TVkSampleCountFlagBits;
       fCountCascadedShadowMapMSAASamples:TpvSizeInt;
       fSurfaceSampleCountFlagBits:TVkSampleCountFlagBits;
       fCountSurfaceMSAASamples:TpvSizeInt;
      private
       fSkyCubeMap:TpvScene3DRendererSkyCubeMap;
       fGGXBRDF:TpvScene3DRendererGGXBRDF;
       fGGXEnvMapCubeMap:TpvScene3DRendererGGXEnvMapCubeMap;
       fCharlieBRDF:TpvScene3DRendererCharlieBRDF;
       fCharlieEnvMapCubeMap:TpvScene3DRendererCharlieEnvMapCubeMap;
       fLambertianEnvMapCubeMap:TpvScene3DRendererLambertianEnvMapCubeMap;
       fSheenELUT:TpvVulkanTexture;
       fShadowMapSampler:TpvVulkanSampler;
       fSSAOSampler:TpvVulkanSampler;
       fSMAAAreaTexture:TpvVulkanTexture;
       fSMAASearchTexture:TpvVulkanTexture;
      public
       constructor Create(const aScene3D:TpvScene3D;const aVulkanDevice:TpvVulkanDevice=nil;const aCountInFlightFrames:TpvSizeInt=MaxInFlightFrames); reintroduce;
       destructor Destroy; override;
       class procedure SetupVulkanDevice(const aVulkanDevice:TpvVulkanDevice); static;
       procedure Prepare;
       procedure AllocateResources;
       procedure ReleaseResources;
      published
       property Scene3D:TpvScene3D read fScene3D;
       property VulkanDevice:TpvVulkanDevice read fVulkanDevice;
       property CountInFlightFrames:TpvSizeInt read fCountInFlightFrames;
       property AntialiasingMode:TpvScene3DRendererAntialiasingMode read fAntialiasingMode write fAntialiasingMode;
       property ShadowMode:TpvScene3DRendererShadowMode read fShadowMode write fShadowMode;
       property TransparencyMode:TpvScene3DRendererTransparencyMode read fTransparencyMode write fTransparencyMode;
       property MaxMSAA:TpvInt32 read fMaxMSAA write fMaxMSAA;
       property MaxShadowMSAA:TpvInt32 read fMaxShadowMSAA write fMaxShadowMSAA;
       property ShadowMapSize:TpvInt32 read fShadowMapSize write fShadowMapSize;
       property BufferDeviceAddress:boolean read fBufferDeviceAddress;
       property MeshFragTypeName:TpvUTF8String read fMeshFragTypeName;
       property MeshFragShadowTypeName:TpvUTF8String read fMeshFragShadowTypeName;
       property OptimizedNonAlphaFormat:TVkFormat read fOptimizedNonAlphaFormat;
       property UseDepthPrepass:boolean read fUseDepthPrepass;
       property UseDemote:boolean read fUseDemote;
       property UseNoDiscard:boolean read fUseNoDiscard;
       property UseOITAlphaTest:boolean read fUseOITAlphaTest;
       property ShadowMapSampleCountFlagBits:TVkSampleCountFlagBits read fShadowMapSampleCountFlagBits;
       property CountCascadedShadowMapMSAASamples:TpvSizeInt read fCountCascadedShadowMapMSAASamples;
       property SurfaceSampleCountFlagBits:TVkSampleCountFlagBits read fSurfaceSampleCountFlagBits;
       property CountSurfaceMSAASamples:TpvSizeInt read fCountSurfaceMSAASamples;
      published
       property SkyCubeMap:TpvScene3DRendererSkyCubeMap read fSkyCubeMap;
       property GGXBRDF:TpvScene3DRendererGGXBRDF read fGGXBRDF;
       property GGXEnvMapCubeMap:TpvScene3DRendererGGXEnvMapCubeMap read fGGXEnvMapCubeMap;
       property CharlieBRDF:TpvScene3DRendererCharlieBRDF read fCharlieBRDF;
       property CharlieEnvMapCubeMap:TpvScene3DRendererCharlieEnvMapCubeMap read fCharlieEnvMapCubeMap;
       property LambertianEnvMapCubeMap:TpvScene3DRendererLambertianEnvMapCubeMap read fLambertianEnvMapCubeMap;
       property SheenELUT:TpvVulkanTexture read fSheenELUT;
       property ShadowMapSampler:TpvVulkanSampler read fShadowMapSampler;
       property SSAOSampler:TpvVulkanSampler read fSSAOSampler;
       property SMAAAreaTexture:TpvVulkanTexture read fSMAAAreaTexture;
       property SMAASearchTexture:TpvVulkanTexture read fSMAASearchTexture;
     end;


implementation

uses PasVulkan.Scene3D.Renderer.Instance;

{ TpvScene3DRendererBaseObject }

constructor TpvScene3DRendererBaseObject.Create(const aParent:TpvScene3DRendererBaseObject);
begin
 inherited Create;

 fParent:=aParent;
 if assigned(fParent) then begin
  if fParent is TpvScene3DRenderer then begin
   fRenderer:=TpvScene3DRenderer(fParent);
  end else begin
   fRenderer:=fParent.fRenderer;
  end;
 end else begin
  fRenderer:=nil;
 end;

 fOwnCircularDoublyLinkedListNode:=TpvScene3DRendererBaseObjectCircularDoublyLinkedListNode.Create;
 fOwnCircularDoublyLinkedListNode.Value:=self;

 fChildrenLock:=TPasMPCriticalSection.Create;
 fChildren:=TpvScene3DRendererBaseObjectCircularDoublyLinkedListNode.Create;

end;

destructor TpvScene3DRendererBaseObject.Destroy;
var Child:TpvScene3DRendererBaseObject;
begin
 fChildrenLock.Acquire;
 try
  while fChildren.PopFromBack(Child) do begin
   FreeAndNil(Child);
  end;
 finally
  fChildrenLock.Release;
 end;
 FreeAndNil(fChildren);
 FreeAndNil(fChildrenLock);
 FreeAndNil(fOwnCircularDoublyLinkedListNode);
 inherited Destroy;
end;

procedure TpvScene3DRendererBaseObject.AfterConstruction;
begin
 inherited AfterConstruction;
 if assigned(fParent) then begin
  fParent.fChildrenLock.Acquire;
  try
   fParent.fChildren.Add(fOwnCircularDoublyLinkedListNode);
  finally
   fParent.fChildrenLock.Release;
  end;
 end;
end;

procedure TpvScene3DRendererBaseObject.BeforeDestruction;
begin
 if assigned(fParent) and not fOwnCircularDoublyLinkedListNode.IsEmpty then begin
  try
   fParent.fChildrenLock.Acquire;
   try
    if not fOwnCircularDoublyLinkedListNode.IsEmpty then begin
     fOwnCircularDoublyLinkedListNode.Remove;
    end;
   finally
    fParent.fChildrenLock.Release;
   end;
  finally
   fParent:=nil;
  end;
 end;
 inherited BeforeDestruction;
end;

{ TpvScene3DRenderer }

constructor TpvScene3DRenderer.Create(const aScene3D:TpvScene3D;const aVulkanDevice:TpvVulkanDevice;const aCountInFlightFrames:TpvSizeInt);
begin
 inherited Create(nil);

 fScene3D:=aScene3D;

 if assigned(aVulkanDevice) then begin
  fVulkanDevice:=aVulkanDevice;
 end else begin
  fVulkanDevice:=fVulkanDevice;
 end;

 fCountInFlightFrames:=aCountInFlightFrames;

 fAntialiasingMode:=TpvScene3DRendererAntialiasingMode.Auto;

 fShadowMode:=TpvScene3DRendererShadowMode.Auto;

 fTransparencyMode:=TpvScene3DRendererTransparencyMode.Auto;

 fMaxMSAA:=0;

 fMaxShadowMSAA:=0;

 fShadowMapSize:=0;

end;

destructor TpvScene3DRenderer.Destroy;
begin
 inherited Destroy;
end;

class procedure TpvScene3DRenderer.SetupVulkanDevice(const aVulkanDevice:TpvVulkanDevice);
begin
 if (aVulkanDevice.PhysicalDevice.DescriptorIndexingFeaturesEXT.descriptorBindingPartiallyBound=VK_FALSE) or
    (aVulkanDevice.PhysicalDevice.DescriptorIndexingFeaturesEXT.runtimeDescriptorArray=VK_FALSE) or
    (aVulkanDevice.PhysicalDevice.DescriptorIndexingFeaturesEXT.shaderSampledImageArrayNonUniformIndexing=VK_FALSE) then begin
  raise EpvApplication.Create('Application','Support for VK_EXT_DESCRIPTOR_INDEXING (descriptorBindingPartiallyBound + runtimeDescriptorArray + shaderSampledImageArrayNonUniformIndexing) is needed',LOG_ERROR);
 end;
{if aVulkanDevice.PhysicalDevice.BufferDeviceAddressFeaturesKHR.bufferDeviceAddress=VK_FALSE then begin
  raise EpvApplication.Create('Application','Support for VK_KHR_buffer_device_address (bufferDeviceAddress) is needed',LOG_ERROR);
 end;}
 if aVulkanDevice.PhysicalDevice.AvailableExtensionNames.IndexOf(VK_KHR_IMAGE_FORMAT_LIST_EXTENSION_NAME)>=0 then begin
  aVulkanDevice.EnabledExtensionNames.Add(VK_KHR_IMAGE_FORMAT_LIST_EXTENSION_NAME);
 end;
 if aVulkanDevice.PhysicalDevice.AvailableExtensionNames.IndexOf(VK_KHR_MAINTENANCE1_EXTENSION_NAME)>=0 then begin
  aVulkanDevice.EnabledExtensionNames.Add(VK_KHR_MAINTENANCE1_EXTENSION_NAME);
 end;
 if aVulkanDevice.PhysicalDevice.AvailableExtensionNames.IndexOf(VK_KHR_MAINTENANCE2_EXTENSION_NAME)>=0 then begin
  aVulkanDevice.EnabledExtensionNames.Add(VK_KHR_MAINTENANCE2_EXTENSION_NAME);
 end;
 if aVulkanDevice.PhysicalDevice.AvailableExtensionNames.IndexOf(VK_KHR_MAINTENANCE3_EXTENSION_NAME)>=0 then begin
  aVulkanDevice.EnabledExtensionNames.Add(VK_KHR_MAINTENANCE3_EXTENSION_NAME);
 end;
 if aVulkanDevice.PhysicalDevice.AvailableExtensionNames.IndexOf(VK_EXT_POST_DEPTH_COVERAGE_EXTENSION_NAME)>=0 then begin
  aVulkanDevice.EnabledExtensionNames.Add(VK_EXT_POST_DEPTH_COVERAGE_EXTENSION_NAME);
 end;
 if aVulkanDevice.PhysicalDevice.AvailableExtensionNames.IndexOf(VK_EXT_FRAGMENT_SHADER_INTERLOCK_EXTENSION_NAME)>=0 then begin
  aVulkanDevice.EnabledExtensionNames.Add(VK_EXT_FRAGMENT_SHADER_INTERLOCK_EXTENSION_NAME);
 end;
 if aVulkanDevice.PhysicalDevice.AvailableExtensionNames.IndexOf(VK_EXT_SHADER_DEMOTE_TO_HELPER_INVOCATION_EXTENSION_NAME)>=0 then begin
  aVulkanDevice.EnabledExtensionNames.Add(VK_EXT_SHADER_DEMOTE_TO_HELPER_INVOCATION_EXTENSION_NAME);
 end;
 if aVulkanDevice.PhysicalDevice.AvailableExtensionNames.IndexOf(VK_EXT_DESCRIPTOR_INDEXING_EXTENSION_NAME)>=0 then begin
  aVulkanDevice.EnabledExtensionNames.Add(VK_EXT_DESCRIPTOR_INDEXING_EXTENSION_NAME);
 end;
 if aVulkanDevice.PhysicalDevice.AvailableExtensionNames.IndexOf(VK_KHR_BUFFER_DEVICE_ADDRESS_EXTENSION_NAME)>=0 then begin
  aVulkanDevice.EnabledExtensionNames.Add(VK_KHR_BUFFER_DEVICE_ADDRESS_EXTENSION_NAME);
 end;
 if aVulkanDevice.PhysicalDevice.AvailableExtensionNames.IndexOf(VK_EXT_HOST_QUERY_RESET_EXTENSION_NAME)>=0 then begin
  aVulkanDevice.EnabledExtensionNames.Add(VK_EXT_HOST_QUERY_RESET_EXTENSION_NAME);
 end;
 if ((aVulkanDevice.Instance.APIVersion and VK_API_VERSION_WITHOUT_PATCH_MASK)<VK_API_VERSION_1_2) and
    (aVulkanDevice.PhysicalDevice.AvailableExtensionNames.IndexOf(VK_KHR_SPIRV_1_4_EXTENSION_NAME)>=0) then begin
  aVulkanDevice.EnabledExtensionNames.Add(VK_KHR_SPIRV_1_4_EXTENSION_NAME);
 end;
end;

procedure TpvScene3DRenderer.Prepare;
var SampleCounts:TVkSampleCountFlags;
    FormatProperties:TVkFormatProperties;
begin

 if fShadowMapSize=0 then begin
  fShadowMapSize:=512;
 end;

 fShadowMapSize:=Max(16,fShadowMapSize);

 fBufferDeviceAddress:=(fVulkanDevice.PhysicalDevice.BufferDeviceAddressFeaturesKHR.bufferDeviceAddress<>VK_FALSE) and
                       (fVulkanDevice.PhysicalDevice.BufferDeviceAddressFeaturesKHR.bufferDeviceAddressCaptureReplay<>VK_FALSE);
 if fBufferDeviceAddress then begin
  fMeshFragTypeName:='matbufref';
 end else begin
  fMeshFragTypeName:='matssbo';
 end;

 FormatProperties:=fVulkanDevice.PhysicalDevice.GetFormatProperties(VK_FORMAT_B10G11R11_UFLOAT_PACK32);
 if //(fVulkanDevice.PhysicalDevice.Properties.deviceType=VK_PHYSICAL_DEVICE_TYPE_INTEGRATED_GPU) and
    ((FormatProperties.linearTilingFeatures and (TVkFormatFeatureFlags(VK_FORMAT_FEATURE_SAMPLED_IMAGE_BIT) or
                                                 TVkFormatFeatureFlags(VK_FORMAT_FEATURE_SAMPLED_IMAGE_FILTER_LINEAR_BIT) or
                                                 TVkFormatFeatureFlags(VK_FORMAT_FEATURE_STORAGE_IMAGE_BIT) or
                                                 TVkFormatFeatureFlags(VK_FORMAT_FEATURE_TRANSFER_DST_BIT) or
                                                 TVkFormatFeatureFlags(VK_FORMAT_FEATURE_TRANSFER_SRC_BIT)))=(TVkFormatFeatureFlags(VK_FORMAT_FEATURE_SAMPLED_IMAGE_BIT) or
                                                                                                              TVkFormatFeatureFlags(VK_FORMAT_FEATURE_SAMPLED_IMAGE_FILTER_LINEAR_BIT) or
                                                                                                              TVkFormatFeatureFlags(VK_FORMAT_FEATURE_STORAGE_IMAGE_BIT) or
                                                                                                              TVkFormatFeatureFlags(VK_FORMAT_FEATURE_TRANSFER_DST_BIT) or
                                                                                                              TVkFormatFeatureFlags(VK_FORMAT_FEATURE_TRANSFER_SRC_BIT))) and
    ((FormatProperties.optimalTilingFeatures and (TVkFormatFeatureFlags(VK_FORMAT_FEATURE_SAMPLED_IMAGE_BIT) or
                                                  TVkFormatFeatureFlags(VK_FORMAT_FEATURE_SAMPLED_IMAGE_FILTER_LINEAR_BIT) or
                                                  TVkFormatFeatureFlags(VK_FORMAT_FEATURE_STORAGE_IMAGE_BIT) or
                                                  TVkFormatFeatureFlags(VK_FORMAT_FEATURE_COLOR_ATTACHMENT_BIT) or
                                                  TVkFormatFeatureFlags(VK_FORMAT_FEATURE_TRANSFER_DST_BIT) or
                                                  TVkFormatFeatureFlags(VK_FORMAT_FEATURE_TRANSFER_SRC_BIT)))=(TVkFormatFeatureFlags(VK_FORMAT_FEATURE_SAMPLED_IMAGE_BIT) or
                                                                                                               TVkFormatFeatureFlags(VK_FORMAT_FEATURE_SAMPLED_IMAGE_FILTER_LINEAR_BIT) or
                                                                                                               TVkFormatFeatureFlags(VK_FORMAT_FEATURE_STORAGE_IMAGE_BIT) or
                                                                                                               TVkFormatFeatureFlags(VK_FORMAT_FEATURE_COLOR_ATTACHMENT_BIT) or
                                                                                                               TVkFormatFeatureFlags(VK_FORMAT_FEATURE_TRANSFER_DST_BIT) or
                                                                                                               TVkFormatFeatureFlags(VK_FORMAT_FEATURE_TRANSFER_SRC_BIT))) then begin
  fOptimizedNonAlphaFormat:=VK_FORMAT_B10G11R11_UFLOAT_PACK32;
 end else begin
  fOptimizedNonAlphaFormat:=VK_FORMAT_R16G16B16A16_SFLOAT;
 end;

 case TpvVulkanVendorID(fVulkanDevice.PhysicalDevice.Properties.vendorID) of
  TpvVulkanVendorID.ImgTec,
  TpvVulkanVendorID.ARM,
  TpvVulkanVendorID.Qualcomm,
  TpvVulkanVendorID.Vivante:begin
   // Tile-based GPUs => Use no depth prepass, as it can be counterproductive for those
   fUseDepthPrepass:=false;
  end;
  else begin
   // Immediate-based GPUs => Use depth prepass, as for which it can bring an advantage
   fUseDepthPrepass:=true;
  end;
 end;

 fUseDemote:=fVulkanDevice.PhysicalDevice.ShaderDemoteToHelperInvocation;

 case TpvVulkanVendorID(fVulkanDevice.PhysicalDevice.Properties.vendorID) of
  TpvVulkanVendorID.Intel:begin
   // Workaround for Intel (i)GPUs, which've problems with discarding fragments in 2x2 fragment blocks at alpha-test usage
   fUseNoDiscard:=not fUseDemote;
   fUseOITAlphaTest:=true;
  end;
  else begin
   fUseNoDiscard:=false;
   fUseOITAlphaTest:=false;
  end;
 end;

 if fAntialiasingMode=TpvScene3DRendererAntialiasingMode.Auto then begin
  case TpvVulkanVendorID(fVulkanDevice.PhysicalDevice.Properties.vendorID) of
   TpvVulkanVendorID.AMD:begin
    if fVulkanDevice.PhysicalDevice.Properties.deviceType=VK_PHYSICAL_DEVICE_TYPE_INTEGRATED_GPU then begin
     fAntialiasingMode:=TpvScene3DRendererAntialiasingMode.FXAA;
    end else begin
     fAntialiasingMode:=TpvScene3DRendererAntialiasingMode.SMAA;
    end;
   end;
   TpvVulkanVendorID.NVIDIA:begin
    if fVulkanDevice.PhysicalDevice.Properties.deviceType=VK_PHYSICAL_DEVICE_TYPE_INTEGRATED_GPU then begin
     fAntialiasingMode:=TpvScene3DRendererAntialiasingMode.FXAA;
    end else begin
     fAntialiasingMode:=TpvScene3DRendererAntialiasingMode.SMAA;
    end;
   end;
   TpvVulkanVendorID.Intel:begin
    if fVulkanDevice.PhysicalDevice.Properties.deviceType=VK_PHYSICAL_DEVICE_TYPE_INTEGRATED_GPU then begin
     fAntialiasingMode:=TpvScene3DRendererAntialiasingMode.FXAA;
    end else begin
     fAntialiasingMode:=TpvScene3DRendererAntialiasingMode.SMAA;
    end;
   end;
   else begin
    if fVulkanDevice.PhysicalDevice.Properties.deviceType=VK_PHYSICAL_DEVICE_TYPE_INTEGRATED_GPU then begin
     fAntialiasingMode:=TpvScene3DRendererAntialiasingMode.DSAA;
    end else begin
     fAntialiasingMode:=TpvScene3DRendererAntialiasingMode.FXAA;
    end;
   end;
  end;
 end;

 SampleCounts:=fVulkanDevice.PhysicalDevice.Properties.limits.framebufferColorSampleCounts and
               fVulkanDevice.PhysicalDevice.Properties.limits.framebufferDepthSampleCounts and
               fVulkanDevice.PhysicalDevice.Properties.limits.framebufferStencilSampleCounts;

 if fMaxShadowMSAA=0 then begin
  case TpvVulkanVendorID(fVulkanDevice.PhysicalDevice.Properties.vendorID) of
   TpvVulkanVendorID.AMD:begin
    fMaxShadowMSAA:=1;
   end;
   TpvVulkanVendorID.NVIDIA:begin
    if fVulkanDevice.PhysicalDevice.Properties.deviceType=VK_PHYSICAL_DEVICE_TYPE_DISCRETE_GPU then begin
     fMaxShadowMSAA:=8;
    end else begin
     fMaxShadowMSAA:=1;
    end;
   end;
   TpvVulkanVendorID.Intel:begin
    fMaxShadowMSAA:=1;
   end;
   else begin
    fMaxShadowMSAA:=1;
   end;
  end;
 end;

 if fMaxMSAA=0 then begin
  case TpvVulkanVendorID(fVulkanDevice.PhysicalDevice.Properties.vendorID) of
   TpvVulkanVendorID.AMD:begin
    fMaxMSAA:=2;
   end;
   TpvVulkanVendorID.NVIDIA:begin
    if fVulkanDevice.PhysicalDevice.Properties.deviceType=VK_PHYSICAL_DEVICE_TYPE_DISCRETE_GPU then begin
     fMaxMSAA:=8;
    end else begin
     fMaxMSAA:=2;
    end;
   end;
   TpvVulkanVendorID.Intel:begin
    fMaxMSAA:=2;
   end;
   else begin
    fMaxMSAA:=2;
   end;
  end;
 end;

 if fShadowMode=TpvScene3DRendererShadowMode.Auto then begin
  fShadowMode:=TpvScene3DRendererShadowMode.PCF;
 end;

 if fShadowMode in [TpvScene3DRendererShadowMode.PCF,TpvScene3DRendererShadowMode.DPCF,TpvScene3DRendererShadowMode.PCSS] then begin
  fMeshFragShadowTypeName:='pcfpcss';
 end else begin
  fMeshFragShadowTypeName:='msm';
 end;

 if fShadowMode=TpvScene3DRendererShadowMode.MSM then begin
  if (fMaxShadowMSAA>=64) and ((SampleCounts and TVkSampleCountFlags(VK_SAMPLE_COUNT_64_BIT))<>0) then begin
   fShadowMapSampleCountFlagBits:=TVkSampleCountFlagBits(VK_SAMPLE_COUNT_64_BIT);
   fCountCascadedShadowMapMSAASamples:=64;
  end else if (fMaxShadowMSAA>=32) and ((SampleCounts and TVkSampleCountFlags(VK_SAMPLE_COUNT_32_BIT))<>0) then begin
   fShadowMapSampleCountFlagBits:=TVkSampleCountFlagBits(VK_SAMPLE_COUNT_32_BIT);
   fCountCascadedShadowMapMSAASamples:=32;
  end else if (fMaxShadowMSAA>=16) and ((SampleCounts and TVkSampleCountFlags(VK_SAMPLE_COUNT_16_BIT))<>0) then begin
   fShadowMapSampleCountFlagBits:=TVkSampleCountFlagBits(VK_SAMPLE_COUNT_16_BIT);
   fCountCascadedShadowMapMSAASamples:=16;
  end else if (fMaxShadowMSAA>=8) and ((SampleCounts and TVkSampleCountFlags(VK_SAMPLE_COUNT_8_BIT))<>0) then begin
   fShadowMapSampleCountFlagBits:=TVkSampleCountFlagBits(VK_SAMPLE_COUNT_8_BIT);
   fCountCascadedShadowMapMSAASamples:=8;
  end else if (fMaxShadowMSAA>=4) and ((SampleCounts and TVkSampleCountFlags(VK_SAMPLE_COUNT_4_BIT))<>0) then begin
   fShadowMapSampleCountFlagBits:=TVkSampleCountFlagBits(VK_SAMPLE_COUNT_4_BIT);
   fCountCascadedShadowMapMSAASamples:=4;
  end else if (fMaxShadowMSAA>=2) and ((SampleCounts and TVkSampleCountFlags(VK_SAMPLE_COUNT_2_BIT))<>0) then begin
   fShadowMapSampleCountFlagBits:=TVkSampleCountFlagBits(VK_SAMPLE_COUNT_2_BIT);
   fCountCascadedShadowMapMSAASamples:=2;
  end else begin
   fShadowMapSampleCountFlagBits:=TVkSampleCountFlagBits(VK_SAMPLE_COUNT_1_BIT);
   fCountCascadedShadowMapMSAASamples:=1;
  end;
 end else begin
  fShadowMapSampleCountFlagBits:=TVkSampleCountFlagBits(VK_SAMPLE_COUNT_1_BIT);
  fCountCascadedShadowMapMSAASamples:=1;
 end;

 if fAntialiasingMode=TpvScene3DRendererAntialiasingMode.MSAA then begin
  if (fMaxMSAA>=64) and ((SampleCounts and TVkSampleCountFlags(VK_SAMPLE_COUNT_64_BIT))<>0) then begin
   fSurfaceSampleCountFlagBits:=TVkSampleCountFlagBits(VK_SAMPLE_COUNT_64_BIT);
   fCountSurfaceMSAASamples:=64;
  end else if (fMaxMSAA>=32) and ((SampleCounts and TVkSampleCountFlags(VK_SAMPLE_COUNT_32_BIT))<>0) then begin
   fSurfaceSampleCountFlagBits:=TVkSampleCountFlagBits(VK_SAMPLE_COUNT_32_BIT);
   fCountSurfaceMSAASamples:=32;
  end else if (fMaxMSAA>=16) and ((SampleCounts and TVkSampleCountFlags(VK_SAMPLE_COUNT_16_BIT))<>0) then begin
   fSurfaceSampleCountFlagBits:=TVkSampleCountFlagBits(VK_SAMPLE_COUNT_16_BIT);
   fCountSurfaceMSAASamples:=16;
  end else if (fMaxMSAA>=8) and ((SampleCounts and TVkSampleCountFlags(VK_SAMPLE_COUNT_8_BIT))<>0) then begin
   fSurfaceSampleCountFlagBits:=TVkSampleCountFlagBits(VK_SAMPLE_COUNT_8_BIT);
   fCountSurfaceMSAASamples:=8;
  end else if (fMaxMSAA>=4) and ((SampleCounts and TVkSampleCountFlags(VK_SAMPLE_COUNT_4_BIT))<>0) then begin
   fSurfaceSampleCountFlagBits:=TVkSampleCountFlagBits(VK_SAMPLE_COUNT_4_BIT);
   fCountSurfaceMSAASamples:=4;
  end else if (fMaxMSAA>=2) and ((SampleCounts and TVkSampleCountFlags(VK_SAMPLE_COUNT_2_BIT))<>0) then begin
   fSurfaceSampleCountFlagBits:=TVkSampleCountFlagBits(VK_SAMPLE_COUNT_2_BIT);
   fCountSurfaceMSAASamples:=2;
  end else begin
   fSurfaceSampleCountFlagBits:=TVkSampleCountFlagBits(VK_SAMPLE_COUNT_1_BIT);
   fCountSurfaceMSAASamples:=1;
   fAntialiasingMode:=TpvScene3DRendererAntialiasingMode.FXAA;
  end;
 end else begin
  fSurfaceSampleCountFlagBits:=TVkSampleCountFlagBits(VK_SAMPLE_COUNT_1_BIT);
  fCountSurfaceMSAASamples:=1;
 end;

 if fTransparencyMode=TpvScene3DRendererTransparencyMode.Auto then begin
  case TpvVulkanVendorID(fVulkanDevice.PhysicalDevice.Properties.vendorID) of
   TpvVulkanVendorID.AMD:begin
    if (fSurfaceSampleCountFlagBits=TVkSampleCountFlagBits(VK_SAMPLE_COUNT_1_BIT)) and
       (fVulkanDevice.EnabledExtensionNames.IndexOf(VK_EXT_POST_DEPTH_COVERAGE_EXTENSION_NAME)>0) then begin
     // >= RDNA, since VK_EXT_post_depth_coverage exists just from RDNA on.
     fTransparencyMode:=TpvScene3DRendererTransparencyMode.SPINLOCKOIT;
    end else begin
     if fVulkanDevice.PhysicalDevice.Properties.deviceType=VK_PHYSICAL_DEVICE_TYPE_INTEGRATED_GPU then begin
      fTransparencyMode:=TpvScene3DRendererTransparencyMode.WBOIT;
     end else begin
      fTransparencyMode:=TpvScene3DRendererTransparencyMode.LOOPOIT;
     end;
    end;
   end;
   TpvVulkanVendorID.NVIDIA:begin
    if fVulkanDevice.EnabledExtensionNames.IndexOf(VK_EXT_POST_DEPTH_COVERAGE_EXTENSION_NAME)>0 then begin
     if (fVulkanDevice.EnabledExtensionNames.IndexOf(VK_EXT_FRAGMENT_SHADER_INTERLOCK_EXTENSION_NAME)>0) and
        fVulkanDevice.PhysicalDevice.FragmentShaderPixelInterlock then begin
      fTransparencyMode:=TpvScene3DRendererTransparencyMode.INTERLOCKOIT;
     end else begin
      fTransparencyMode:=TpvScene3DRendererTransparencyMode.SPINLOCKOIT;
     end;
    end else begin
     if fVulkanDevice.PhysicalDevice.Properties.deviceType=VK_PHYSICAL_DEVICE_TYPE_INTEGRATED_GPU then begin
      fTransparencyMode:=TpvScene3DRendererTransparencyMode.WBOIT;
     end else begin
      fTransparencyMode:=TpvScene3DRendererTransparencyMode.MBOIT;
     end;
    end;
   end;
   TpvVulkanVendorID.Intel:begin
    if (fSurfaceSampleCountFlagBits=TVkSampleCountFlagBits(VK_SAMPLE_COUNT_1_BIT)) and
       (fVulkanDevice.EnabledExtensionNames.IndexOf(VK_EXT_FRAGMENT_SHADER_INTERLOCK_EXTENSION_NAME)>0) and
       fVulkanDevice.PhysicalDevice.FragmentShaderPixelInterlock then begin
     fTransparencyMode:=TpvScene3DRendererTransparencyMode.INTERLOCKOIT;
    end else begin
     if fVulkanDevice.PhysicalDevice.Properties.deviceType=VK_PHYSICAL_DEVICE_TYPE_INTEGRATED_GPU then begin
      fTransparencyMode:=TpvScene3DRendererTransparencyMode.WBOIT;
     end else begin
      fTransparencyMode:=TpvScene3DRendererTransparencyMode.MBOIT;
     end;
    end;
   end;
   else begin
    if fVulkanDevice.PhysicalDevice.Properties.deviceType=VK_PHYSICAL_DEVICE_TYPE_INTEGRATED_GPU then begin
     fTransparencyMode:=TpvScene3DRendererTransparencyMode.Direct;
    end else begin
     fTransparencyMode:=TpvScene3DRendererTransparencyMode.WBOIT;
    end;
   end;
  end;
 end;

end;

procedure TpvScene3DRenderer.AllocateResources;
var Index:TpvSizeInt;
    Stream:TStream;
    UniversalQueue:TpvVulkanQueue;
    UniversalCommandPool:TpvVulkanCommandPool;
    UniversalCommandBuffer:TpvVulkanCommandBuffer;
    UniversalFence:TpvVulkanFence;
begin

 fSkyCubeMap:=TpvScene3DRendererSkyCubeMap.Create(fOptimizedNonAlphaFormat);

 fGGXBRDF:=TpvScene3DRendererGGXBRDF.Create;

 fGGXEnvMapCubeMap:=TpvScene3DRendererGGXEnvMapCubeMap.Create(fSkyCubeMap.DescriptorImageInfo,fOptimizedNonAlphaFormat);

 fCharlieBRDF:=TpvScene3DRendererCharlieBRDF.Create;

 fCharlieEnvMapCubeMap:=TpvScene3DRendererCharlieEnvMapCubeMap.Create(fSkyCubeMap.DescriptorImageInfo,fOptimizedNonAlphaFormat);

 fLambertianEnvMapCubeMap:=TpvScene3DRendererLambertianEnvMapCubeMap.Create(fSkyCubeMap.DescriptorImageInfo,fOptimizedNonAlphaFormat);

 case fShadowMode of

  TpvScene3DRendererShadowMode.MSM:begin

   fShadowMapSampler:=TpvVulkanSampler.Create(fVulkanDevice,
                                              TVkFilter.VK_FILTER_LINEAR,
                                              TVkFilter.VK_FILTER_LINEAR,
                                              TVkSamplerMipmapMode.VK_SAMPLER_MIPMAP_MODE_LINEAR,
                                              VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_BORDER,
                                              VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_BORDER,
                                              VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_BORDER,
                                              0.0,
                                              false,
                                              0.0,
                                              false,
                                              VK_COMPARE_OP_ALWAYS,
                                              0.0,
                                              0.0,
                                              VK_BORDER_COLOR_FLOAT_OPAQUE_WHITE,
                                              false);

  end;

  TpvScene3DRendererShadowMode.PCF:begin

   fShadowMapSampler:=TpvVulkanSampler.Create(fVulkanDevice,
                                              TVkFilter.VK_FILTER_LINEAR,
                                              TVkFilter.VK_FILTER_LINEAR,
                                              TVkSamplerMipmapMode.VK_SAMPLER_MIPMAP_MODE_NEAREST,
                                              VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_BORDER,
                                              VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_BORDER,
                                              VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_BORDER,
                                              0.0,
                                              false,
                                              0.0,
                                              true,
                                              VK_COMPARE_OP_GREATER,
                                              0.0,
                                              0.0,
                                              VK_BORDER_COLOR_FLOAT_OPAQUE_WHITE,
                                              false);

  end;

  else begin

   fShadowMapSampler:=TpvVulkanSampler.Create(fVulkanDevice,
                                              TVkFilter.VK_FILTER_NEAREST,
                                              TVkFilter.VK_FILTER_NEAREST,
                                              TVkSamplerMipmapMode.VK_SAMPLER_MIPMAP_MODE_NEAREST,
                                              VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_BORDER,
                                              VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_BORDER,
                                              VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_BORDER,
                                              0.0,
                                              false,
                                              0.0,
                                              false,
                                              VK_COMPARE_OP_ALWAYS,
                                              0.0,
                                              0.0,
                                              VK_BORDER_COLOR_FLOAT_OPAQUE_WHITE,
                                              false);
  end;

 end;

 fSSAOSampler:=TpvVulkanSampler.Create(fVulkanDevice,
                                       TVkFilter.VK_FILTER_LINEAR,
                                       TVkFilter.VK_FILTER_LINEAR,
                                       TVkSamplerMipmapMode.VK_SAMPLER_MIPMAP_MODE_LINEAR,
                                       VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_BORDER,
                                       VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_BORDER,
                                       VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_BORDER,
                                       0.0,
                                       false,
                                       0.0,
                                       false,
                                       VK_COMPARE_OP_ALWAYS,
                                       0.0,
                                       0.0,
                                       VK_BORDER_COLOR_FLOAT_OPAQUE_WHITE,
                                       false);

 UniversalQueue:=fVulkanDevice.UniversalQueue;
 try

  UniversalCommandPool:=TpvVulkanCommandPool.Create(fVulkanDevice,
                                                    fVulkanDevice.UniversalQueueFamilyIndex,
                                                    TVkCommandPoolCreateFlags(VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT));
  try

   UniversalCommandBuffer:=TpvVulkanCommandBuffer.Create(UniversalCommandPool,
                                                         VK_COMMAND_BUFFER_LEVEL_PRIMARY);
   try

    UniversalFence:=TpvVulkanFence.Create(fVulkanDevice);
    try

     case fAntialiasingMode of

      TpvScene3DRendererAntialiasingMode.SMAA:begin

       fSMAAAreaTexture:=TpvVulkanTexture.CreateFromMemory(fVulkanDevice,
                                                           UniversalQueue,
                                                           UniversalCommandBuffer,
                                                           UniversalFence,
                                                           UniversalQueue,
                                                           UniversalCommandBuffer,
                                                           UniversalFence,
                                                           VK_FORMAT_R8G8_UNORM,
                                                           VK_SAMPLE_COUNT_1_BIT,
                                                           PasVulkan.Scene3D.Renderer.SMAAData.AREATEX_WIDTH,
                                                           PasVulkan.Scene3D.Renderer.SMAAData.AREATEX_HEIGHT,
                                                           0,
                                                           0,
                                                           1,
                                                           0,
                                                           [TpvVulkanTextureUsageFlag.General,
                                                            TpvVulkanTextureUsageFlag.TransferDst,
                                                            TpvVulkanTextureUsageFlag.TransferSrc,
                                                            TpvVulkanTextureUsageFlag.Sampled],
                                                           @PasVulkan.Scene3D.Renderer.SMAAData.AreaTexBytes[0],
                                                           PasVulkan.Scene3D.Renderer.SMAAData.AREATEX_SIZE,
                                                           false,
                                                           false,
                                                           0,
                                                           true,
                                                           false);

       fSMAASearchTexture:=TpvVulkanTexture.CreateFromMemory(fVulkanDevice,
                                                             UniversalQueue,
                                                             UniversalCommandBuffer,
                                                             UniversalFence,
                                                             UniversalQueue,
                                                             UniversalCommandBuffer,
                                                             UniversalFence,
                                                             VK_FORMAT_R8_UNORM,
                                                             VK_SAMPLE_COUNT_1_BIT,
                                                             PasVulkan.Scene3D.Renderer.SMAAData.SEARCHTEX_WIDTH,
                                                             PasVulkan.Scene3D.Renderer.SMAAData.SEARCHTEX_HEIGHT,
                                                             0,
                                                             0,
                                                             1,
                                                             0,
                                                             [TpvVulkanTextureUsageFlag.General,
                                                              TpvVulkanTextureUsageFlag.TransferDst,
                                                              TpvVulkanTextureUsageFlag.TransferSrc,
                                                              TpvVulkanTextureUsageFlag.Sampled],
                                                             @PasVulkan.Scene3D.Renderer.SMAAData.SearchTexBytes[0],
                                                             PasVulkan.Scene3D.Renderer.SMAAData.SEARCHTEX_SIZE,
                                                             false,
                                                             false,
                                                             0,
                                                             true,
                                                             false);


      end;
      else begin
      end;
     end;

     Stream:=pvApplication.Assets.GetAssetStream('textures/sheenelut.png');
     try
      fSheenELUT:=TpvVulkanTexture.CreateFromMemory(fVulkanDevice,
                                                    UniversalQueue,
                                                    UniversalCommandBuffer,
                                                    UniversalFence,
                                                    UniversalQueue,
                                                    UniversalCommandBuffer,
                                                    UniversalFence,
                                                    VK_FORMAT_R8_UNORM,
                                                    VK_SAMPLE_COUNT_1_BIT,
                                                    PasVulkan.Scene3D.Renderer.SheenELUTData.SheenELUTWidth,
                                                    PasVulkan.Scene3D.Renderer.SheenELUTData.SheenELUTHeight,
                                                    0,
                                                    0,
                                                    1,
                                                    0,
                                                    [TpvVulkanTextureUsageFlag.General,
                                                     TpvVulkanTextureUsageFlag.TransferDst,
                                                     TpvVulkanTextureUsageFlag.TransferSrc,
                                                     TpvVulkanTextureUsageFlag.Sampled],
                                                    @PasVulkan.Scene3D.Renderer.SheenELUTData.SheenELUTDataBytes[0],
                                                    SizeOf(PasVulkan.Scene3D.Renderer.SheenELUTData.TSheenELUTData),
                                                    false,
                                                    false,
                                                    0,
                                                    true,
                                                    false);
      fSheenELUT.UpdateSampler;
     finally
      FreeAndNil(Stream);
     end;

    finally
     FreeAndNil(UniversalFence);
    end;

   finally
    FreeAndNil(UniversalCommandBuffer);
   end;

  finally
   FreeAndNil(UniversalCommandPool);
  end;

 finally
  UniversalQueue:=nil;
 end;

end;

procedure TpvScene3DRenderer.ReleaseResources;
begin

 FreeAndNil(fShadowMapSampler);

 FreeAndNil(fSSAOSampler);

 FreeAndNil(fSMAAAreaTexture);
 FreeAndNil(fSMAASearchTexture);

 FreeAndNil(fSheenELUT);

 FreeAndNil(fCharlieEnvMapCubeMap);

 FreeAndNil(fCharlieBRDF);

 FreeAndNil(fGGXEnvMapCubeMap);

 FreeAndNil(fGGXBRDF);

 FreeAndNil(fLambertianEnvMapCubeMap);

 FreeAndNil(fSkyCubeMap);

end;

end.
