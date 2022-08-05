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
unit PasVulkan.Scene3D.Renderer.Passes.ForwardRenderPass;
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
     Vulkan,
     PasVulkan.Types,
     PasVulkan.Math,
     PasVulkan.Framework,
     PasVulkan.Application,
     PasVulkan.FrameGraph,
     PasVulkan.Scene3D,
     PasVulkan.Scene3D.Renderer.Globals,
     PasVulkan.Scene3D.Renderer,
     PasVulkan.Scene3D.Renderer.Instance,
     PasVulkan.Scene3D.Renderer.SkyBox;

type { TpvScene3DRendererInstancePassesForwardRenderPass }
     TpvScene3DRendererInstancePassesForwardRenderPass=class(TpvFrameGraph.TRenderPass)
      private
       fOnSetRenderPassResourcesDone:boolean;
       procedure OnSetRenderPassResources(const aCommandBuffer:TpvVulkanCommandBuffer;
                                          const aPipelineLayout:TpvVulkanPipelineLayout;
                                          const aRenderPassIndex:TpvSizeInt;
                                          const aPreviousInFlightFrameIndex:TpvSizeInt;
                                          const aInFlightFrameIndex:TpvSizeInt);
      public
       fVulkanRenderPass:TpvVulkanRenderPass;
       fInstance:TpvScene3DRendererInstance;
       fResourceCascadedShadowMap:TpvFrameGraph.TPass.TUsedImageResource;
       fResourceSSAO:TpvFrameGraph.TPass.TUsedImageResource;
       fResourceColor:TpvFrameGraph.TPass.TUsedImageResource;
       fResourceDepth:TpvFrameGraph.TPass.TUsedImageResource;
       fMeshVertexShaderModule:TpvVulkanShaderModule;
       fMeshFragmentShaderModule:TpvVulkanShaderModule;
       fMeshMaskedFragmentShaderModule:TpvVulkanShaderModule;
       fMeshDepthFragmentShaderModule:TpvVulkanShaderModule;
       fMeshDepthMaskedFragmentShaderModule:TpvVulkanShaderModule;
       fGlobalVulkanDescriptorSetLayout:TpvVulkanDescriptorSetLayout;
       fGlobalVulkanDescriptorPool:TpvVulkanDescriptorPool;
       fGlobalVulkanDescriptorSets:array[0..MaxInFlightFrames-1] of TpvVulkanDescriptorSet;
       fVulkanPipelineShaderStageMeshVertex:TpvVulkanPipelineShaderStage;
       fVulkanPipelineShaderStageMeshFragment:TpvVulkanPipelineShaderStage;
       fVulkanPipelineShaderStageMeshMaskedFragment:TpvVulkanPipelineShaderStage;
       fVulkanPipelineShaderStageMeshDepthFragment:TpvVulkanPipelineShaderStage;
       fVulkanPipelineShaderStageMeshDepthMaskedFragment:TpvVulkanPipelineShaderStage;
       fVulkanGraphicsPipelines:array[boolean,TpvScene3D.TMaterial.TAlphaMode] of TpvScene3D.TGraphicsPipelines;
       fVulkanPipelineLayout:TpvVulkanPipelineLayout;
       fSkyBox:TpvScene3DRendererSkyBox;
       constructor Create(const aFrameGraph:TpvFrameGraph;const aInstance:TpvScene3DRendererInstance); reintroduce;
       destructor Destroy; override;
       procedure Show; override;
       procedure Hide; override;
       procedure AfterCreateSwapChain; override;
       procedure BeforeDestroySwapChain; override;
       procedure Update(const aUpdateInFlightFrameIndex,aUpdateFrameIndex:TpvSizeInt); override;
       procedure Execute(const aCommandBuffer:TpvVulkanCommandBuffer;const aInFlightFrameIndex,aFrameIndex:TpvSizeInt); override;
     end;

implementation

{ TpvScene3DRendererInstancePassesForwardRenderPass }

constructor TpvScene3DRendererInstancePassesForwardRenderPass.Create(const aFrameGraph:TpvFrameGraph;const aInstance:TpvScene3DRendererInstance);
begin
inherited Create(aFrameGraph);

 fInstance:=aInstance;

 Name:='ForwardRendering';

 MultiviewMask:=fInstance.SurfaceMultiviewMask;

 Queue:=aFrameGraph.UniversalQueue;

 Size:=TpvFrameGraph.TImageSize.Create(TpvFrameGraph.TImageSize.TKind.SurfaceDependent,
                                       1.0,
                                       1.0,
                                       1.0,
                                       fInstance.CountSurfaceViews);

 fResourceCascadedShadowMap:=AddImageInput('resourcetype_cascadedshadowmap_data',
                                           'resource_cascadedshadowmap_data_final',
                                           VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
                                           []
                                          );

 fResourceSSAO:=AddImageInput('resourcetype_ssao_final',
                              'resource_ssao_data_final',
                              VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
                              []
                             );

 if fInstance.Renderer.SurfaceSampleCountFlagBits=TVkSampleCountFlagBits(VK_SAMPLE_COUNT_1_BIT) then begin

  fResourceColor:=AddImageOutput('resourcetype_color_optimized_non_alpha',
                                 'resource_forwardrendering_color',
                                 VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
                                 TpvFrameGraph.TLoadOp.Create(TpvFrameGraph.TLoadOp.TKind.Clear,
                                                              TpvVector4.InlineableCreate(0.0,0.0,0.0,1.0)),
                                 [TpvFrameGraph.TResourceTransition.TFlag.Attachment]
                                );

 fResourceDepth:=AddImageDepthInput('resourcetype_depth',
                                    'resource_depth_data',
                                    VK_IMAGE_LAYOUT_DEPTH_ATTACHMENT_STENCIL_READ_ONLY_OPTIMAL,//VK_IMAGE_LAYOUT_DEPTH_STENCIL_READ_ONLY_OPTIMAL,//VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL,
                                    [TpvFrameGraph.TResourceTransition.TFlag.Attachment]
                                   );{}

{ fResourceDepth:=AddImageDepthOutput('resourcetype_depth',
                                      'resource_depth_data',
                                      VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL,
                                      TpvFrameGraph.TLoadOp.Create(TpvFrameGraph.TLoadOp.TKind.Clear,
                                                                   TpvVector4.InlineableCreate(IfThen(fInstance.ZFar<0.0,0.0,1.0),0.0,0.0,0.0)),
                                      [TpvFrameGraph.TResourceTransition.TFlag.Attachment]
                                     ); {}

 end else begin

  fResourceColor:=AddImageOutput('resourcetype_msaa_color_optimized_non_alpha',
                                 'resource_forwardrendering_msaa_color',
                                 VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
                                 TpvFrameGraph.TLoadOp.Create(TpvFrameGraph.TLoadOp.TKind.Clear,
                                                              TpvVector4.InlineableCreate(0.0,0.0,0.0,1.0)),
                                 [TpvFrameGraph.TResourceTransition.TFlag.Attachment]
                                );

  fResourceColor:=AddImageResolveOutput('resourcetype_color_optimized_non_alpha',
                                        'resource_forwardrendering_color',
                                        'resource_forwardrendering_msaa_color',
                                        VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
                                        TpvFrameGraph.TLoadOp.Create(TpvFrameGraph.TLoadOp.TKind.DontCare,
                                                                     TpvVector4.InlineableCreate(0.0,0.0,0.0,1.0)),
                                        [TpvFrameGraph.TResourceTransition.TFlag.Attachment]
                                       );

  fResourceDepth:=AddImageDepthInput('resourcetype_msaa_depth',
                                     'resource_msaa_depth_data',
                                     VK_IMAGE_LAYOUT_DEPTH_ATTACHMENT_STENCIL_READ_ONLY_OPTIMAL,//VK_IMAGE_LAYOUT_DEPTH_STENCIL_READ_ONLY_OPTIMAL,//VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL,
                                     [TpvFrameGraph.TResourceTransition.TFlag.Attachment]
                                    );

{fResourceDepth:=AddImageDepthOutput('resourcetype_msaa_depth',
                                     'resource_msaa_depth_data',
                                     VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL,
                                     TpvFrameGraph.TLoadOp.Create(TpvFrameGraph.TLoadOp.TKind.Clear,
                                                                  TpvVector4.InlineableCreate(IfThen(fInstance.ZFar<0.0,0.0,1.0),0.0,0.0,0.0)),
                                     [TpvFrameGraph.TResourceTransition.TFlag.Attachment]
                                    );{}

 end;

end;

destructor TpvScene3DRendererInstancePassesForwardRenderPass.Destroy;
begin
 inherited Destroy;
end;

procedure TpvScene3DRendererInstancePassesForwardRenderPass.Show;
var Index:TpvSizeInt;
    Stream:TStream;
begin
 inherited Show;

 Stream:=pvApplication.Assets.GetAssetStream('shaders/mesh_vert.spv');
 try
  fMeshVertexShaderModule:=TpvVulkanShaderModule.Create(pvApplication.VulkanDevice,Stream);
 finally
  Stream.Free;
 end;

 Stream:=pvApplication.Assets.GetAssetStream('shaders/mesh_'+fInstance.Renderer.MeshFragTypeName+'_'+fInstance.Renderer.MeshFragShadowTypeName+'_frag.spv');
 try
  fMeshFragmentShaderModule:=TpvVulkanShaderModule.Create(pvApplication.VulkanDevice,Stream);
 finally
  Stream.Free;
 end;

 if fInstance.Renderer.UseDemote then begin
  if fInstance.Renderer.SurfaceSampleCountFlagBits=TVkSampleCountFlagBits(VK_SAMPLE_COUNT_1_BIT) then begin
  Stream:=pvApplication.Assets.GetAssetStream('shaders/mesh_'+fInstance.Renderer.MeshFragTypeName+'_'+fInstance.Renderer.MeshFragShadowTypeName+'_masked_demote_frag.spv');
  end else begin
   Stream:=pvApplication.Assets.GetAssetStream('shaders/mesh_'+fInstance.Renderer.MeshFragTypeName+'_'+fInstance.Renderer.MeshFragShadowTypeName+'_masked_demote_msaa_frag.spv');
  end;
 end else if fInstance.Renderer.UseNoDiscard then begin
  if fInstance.ZFar<0.0 then begin
   if fInstance.Renderer.SurfaceSampleCountFlagBits=TVkSampleCountFlagBits(VK_SAMPLE_COUNT_1_BIT) then begin
    Stream:=pvApplication.Assets.GetAssetStream('shaders/mesh_'+fInstance.Renderer.MeshFragTypeName+'_'+fInstance.Renderer.MeshFragShadowTypeName+'_masked_nodiscard_reversedz_frag.spv');
   end else begin
    Stream:=pvApplication.Assets.GetAssetStream('shaders/mesh_'+fInstance.Renderer.MeshFragTypeName+'_'+fInstance.Renderer.MeshFragShadowTypeName+'_masked_nodiscard_reversedz_msaa_frag.spv');
   end;
  end else begin
   if fInstance.Renderer.SurfaceSampleCountFlagBits=TVkSampleCountFlagBits(VK_SAMPLE_COUNT_1_BIT) then begin
    Stream:=pvApplication.Assets.GetAssetStream('shaders/mesh_'+fInstance.Renderer.MeshFragTypeName+'_'+fInstance.Renderer.MeshFragShadowTypeName+'_masked_nodiscard_frag.spv');
   end else begin
    Stream:=pvApplication.Assets.GetAssetStream('shaders/mesh_'+fInstance.Renderer.MeshFragTypeName+'_'+fInstance.Renderer.MeshFragShadowTypeName+'_masked_nodiscard_msaa_frag.spv');
   end;
  end;
 end else begin
  if fInstance.Renderer.SurfaceSampleCountFlagBits=TVkSampleCountFlagBits(VK_SAMPLE_COUNT_1_BIT) then begin
   Stream:=pvApplication.Assets.GetAssetStream('shaders/mesh_'+fInstance.Renderer.MeshFragTypeName+'_'+fInstance.Renderer.MeshFragShadowTypeName+'_masked_frag.spv');
  end else begin
   Stream:=pvApplication.Assets.GetAssetStream('shaders/mesh_'+fInstance.Renderer.MeshFragTypeName+'_'+fInstance.Renderer.MeshFragShadowTypeName+'_masked_msaa_frag.spv');
  end;
 end;
 try
  fMeshMaskedFragmentShaderModule:=TpvVulkanShaderModule.Create(pvApplication.VulkanDevice,Stream);
 finally
  Stream.Free;
 end;

 if fInstance.Renderer.UseDepthPrepass then begin

  Stream:=pvApplication.Assets.GetAssetStream('shaders/mesh_'+fInstance.Renderer.MeshFragTypeName+'_depth_frag.spv');
  try
   fMeshDepthFragmentShaderModule:=TpvVulkanShaderModule.Create(pvApplication.VulkanDevice,Stream);
  finally
   Stream.Free;
  end;

  if fInstance.Renderer.UseDemote then begin
   Stream:=pvApplication.Assets.GetAssetStream('shaders/mesh_'+fInstance.Renderer.MeshFragTypeName+'_depth_masked_demote_frag.spv');
  end else if fInstance.Renderer.UseNoDiscard then begin
   if fInstance.ZFar<0.0 then begin
    Stream:=pvApplication.Assets.GetAssetStream('shaders/mesh_'+fInstance.Renderer.MeshFragTypeName+'_depth_masked_nodiscard_reversedz_frag.spv');
   end else begin
    Stream:=pvApplication.Assets.GetAssetStream('shaders/mesh_'+fInstance.Renderer.MeshFragTypeName+'_depth_masked_nodiscard_frag.spv');
   end;
  end else begin
   Stream:=pvApplication.Assets.GetAssetStream('shaders/mesh_'+fInstance.Renderer.MeshFragTypeName+'_depth_masked_frag.spv');
  end;
  try
   fMeshDepthMaskedFragmentShaderModule:=TpvVulkanShaderModule.Create(pvApplication.VulkanDevice,Stream);
  finally
   Stream.Free;
  end;

 end;

 fVulkanPipelineShaderStageMeshVertex:=TpvVulkanPipelineShaderStage.Create(VK_SHADER_STAGE_VERTEX_BIT,fMeshVertexShaderModule,'main');

 fVulkanPipelineShaderStageMeshFragment:=TpvVulkanPipelineShaderStage.Create(VK_SHADER_STAGE_FRAGMENT_BIT,fMeshFragmentShaderModule,'main');

 fVulkanPipelineShaderStageMeshMaskedFragment:=TpvVulkanPipelineShaderStage.Create(VK_SHADER_STAGE_FRAGMENT_BIT,fMeshMaskedFragmentShaderModule,'main');

 if fInstance.Renderer.UseDepthPrepass then begin

  fVulkanPipelineShaderStageMeshDepthFragment:=TpvVulkanPipelineShaderStage.Create(VK_SHADER_STAGE_FRAGMENT_BIT,fMeshDepthFragmentShaderModule,'main');

  fVulkanPipelineShaderStageMeshDepthMaskedFragment:=TpvVulkanPipelineShaderStage.Create(VK_SHADER_STAGE_FRAGMENT_BIT,fMeshDepthMaskedFragmentShaderModule,'main');

 end;

 fSkyBox:=TpvScene3DRendererSkyBox.Create(fInstance.Renderer.Scene3D,
                                          fInstance.Renderer.SkyCubeMap.DescriptorImageInfo);

end;

procedure TpvScene3DRendererInstancePassesForwardRenderPass.Hide;
begin

 FreeAndNil(fSkyBox);

 FreeAndNil(fVulkanPipelineShaderStageMeshVertex);

 FreeAndNil(fVulkanPipelineShaderStageMeshFragment);

 FreeAndNil(fVulkanPipelineShaderStageMeshMaskedFragment);

 if fInstance.Renderer.UseDepthPrepass then begin

  FreeAndNil(fVulkanPipelineShaderStageMeshDepthFragment);

  FreeAndNil(fVulkanPipelineShaderStageMeshDepthMaskedFragment);

 end;

 FreeAndNil(fMeshVertexShaderModule);

 FreeAndNil(fMeshFragmentShaderModule);

 FreeAndNil(fMeshMaskedFragmentShaderModule);

 if fInstance.Renderer.UseDepthPrepass then begin

  FreeAndNil(fMeshDepthFragmentShaderModule);

  FreeAndNil(fMeshDepthMaskedFragmentShaderModule);

 end;

 inherited Hide;
end;

procedure TpvScene3DRendererInstancePassesForwardRenderPass.AfterCreateSwapChain;
var InFlightFrameIndex:TpvSizeInt;
    DepthPrePass:boolean;
    AlphaMode:TpvScene3D.TMaterial.TAlphaMode;
    PrimitiveTopology:TpvScene3D.TPrimitiveTopology;
    DoubleSided:TpvScene3D.TDoubleSided;
    VulkanGraphicsPipeline:TpvVulkanGraphicsPipeline;
begin

 inherited AfterCreateSwapChain;

 fVulkanRenderPass:=VulkanRenderPass;

 fGlobalVulkanDescriptorSetLayout:=TpvVulkanDescriptorSetLayout.Create(pvApplication.VulkanDevice);
 fGlobalVulkanDescriptorSetLayout.AddBinding(0,
                                             VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
                                             3,
                                             TVkShaderStageFlags(VK_SHADER_STAGE_FRAGMENT_BIT),
                                             []);
 fGlobalVulkanDescriptorSetLayout.AddBinding(1,
                                             VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
                                             3,
                                             TVkShaderStageFlags(VK_SHADER_STAGE_FRAGMENT_BIT),
                                             []);
 fGlobalVulkanDescriptorSetLayout.AddBinding(2,
                                             VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,
                                             1,
                                             TVkShaderStageFlags(VK_SHADER_STAGE_FRAGMENT_BIT),
                                             []);
 fGlobalVulkanDescriptorSetLayout.AddBinding(3,
                                             VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
                                             1,
                                             TVkShaderStageFlags(VK_SHADER_STAGE_FRAGMENT_BIT),
                                             []);
 fGlobalVulkanDescriptorSetLayout.AddBinding(4,
                                             VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
                                             2,
                                             TVkShaderStageFlags(VK_SHADER_STAGE_FRAGMENT_BIT),
                                             []);
 fGlobalVulkanDescriptorSetLayout.Initialize;

 fGlobalVulkanDescriptorPool:=TpvVulkanDescriptorPool.Create(pvApplication.VulkanDevice,TVkDescriptorPoolCreateFlags(VK_DESCRIPTOR_POOL_CREATE_FREE_DESCRIPTOR_SET_BIT),fInstance.Renderer.CountInFlightFrames);
 fGlobalVulkanDescriptorPool.AddDescriptorPoolSize(VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,9*fInstance.Renderer.CountInFlightFrames);
 fGlobalVulkanDescriptorPool.AddDescriptorPoolSize(VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,1*fInstance.Renderer.CountInFlightFrames);
 fGlobalVulkanDescriptorPool.Initialize;

 for InFlightFrameIndex:=0 to FrameGraph.CountInFlightFrames-1 do begin
  fGlobalVulkanDescriptorSets[InFlightFrameIndex]:=TpvVulkanDescriptorSet.Create(fGlobalVulkanDescriptorPool,
                                                                                 fGlobalVulkanDescriptorSetLayout);
  fGlobalVulkanDescriptorSets[InFlightFrameIndex].WriteToDescriptorSet(0,
                                                                       0,
                                                                       3,
                                                                       TVkDescriptorType(VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER),
                                                                       [fInstance.Renderer.GGXBRDF.DescriptorImageInfo,
                                                                        fInstance.Renderer.CharlieBRDF.DescriptorImageInfo,
                                                                        fInstance.Renderer.SheenELUT.DescriptorImageInfo],
                                                                       [],
                                                                       [],
                                                                       false);
  fGlobalVulkanDescriptorSets[InFlightFrameIndex].WriteToDescriptorSet(1,
                                                                       0,
                                                                       3,
                                                                       TVkDescriptorType(VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER),
                                                                       [fInstance.Renderer.GGXEnvMapCubeMap.DescriptorImageInfo,
                                                                        fInstance.Renderer.CharlieEnvMapCubeMap.DescriptorImageInfo,
                                                                        fInstance.Renderer.LambertianEnvMapCubeMap.DescriptorImageInfo],
                                                                       [],
                                                                       [],
                                                                       false);
  fGlobalVulkanDescriptorSets[InFlightFrameIndex].WriteToDescriptorSet(2,
                                                                       0,
                                                                       1,
                                                                       TVkDescriptorType(VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER),
                                                                       [],
                                                                       [fInstance.CascadedShadowMapVulkanUniformBuffers[InFlightFrameIndex].DescriptorBufferInfo],
                                                                       [],
                                                                       false);
  fGlobalVulkanDescriptorSets[InFlightFrameIndex].WriteToDescriptorSet(3,
                                                                       0,
                                                                       1,
                                                                       TVkDescriptorType(VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER),
                                                                       [TVkDescriptorImageInfo.Create(fInstance.Renderer.ShadowMapSampler.Handle,
                                                                                                      fResourceCascadedShadowMap.VulkanImageViews[InFlightFrameIndex].Handle,
                                                                                                      fResourceCascadedShadowMap.ResourceTransition.Layout)],// TVkImageLayout(VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL))],
                                                                       [],
                                                                       [],
                                                                       false);
  fGlobalVulkanDescriptorSets[InFlightFrameIndex].WriteToDescriptorSet(4,
                                                                       0,
                                                                       2,
                                                                       TVkDescriptorType(VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER),
                                                                       [TVkDescriptorImageInfo.Create(fInstance.Renderer.SSAOSampler.Handle,
                                                                                                      fResourceSSAO.VulkanImageViews[InFlightFrameIndex].Handle,
                                                                                                      fResourceSSAO.ResourceTransition.Layout),// TVkImageLayout(VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL))],
                                                                        // Duplicate as dummy really non-used opaque texture
                                                                        TVkDescriptorImageInfo.Create(fInstance.Renderer.SSAOSampler.Handle,
                                                                                                      fResourceSSAO.VulkanImageViews[InFlightFrameIndex].Handle,
                                                                                                      fResourceSSAO.ResourceTransition.Layout)],// TVkImageLayout(VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL))
                                                                       [],
                                                                       [],
                                                                       false);
  fGlobalVulkanDescriptorSets[InFlightFrameIndex].Flush;
 end;

 fVulkanPipelineLayout:=TpvVulkanPipelineLayout.Create(pvApplication.VulkanDevice);
 fVulkanPipelineLayout.AddPushConstantRange(TVkShaderStageFlags(VK_SHADER_STAGE_VERTEX_BIT),0,SizeOf(TpvScene3D.TVertexStagePushConstants));
 fVulkanPipelineLayout.AddDescriptorSetLayout(fInstance.Renderer.Scene3D.GlobalVulkanDescriptorSetLayout);
 fVulkanPipelineLayout.AddDescriptorSetLayout(fGlobalVulkanDescriptorSetLayout);
 fVulkanPipelineLayout.Initialize;

 for DepthPrePass:=false to fInstance.Renderer.UseDepthPrepass do begin
  for AlphaMode:=Low(TpvScene3D.TMaterial.TAlphaMode) to High(TpvScene3D.TMaterial.TAlphaMode) do begin
   for PrimitiveTopology:=Low(TpvScene3D.TPrimitiveTopology) to High(TpvScene3D.TPrimitiveTopology) do begin
    for DoubleSided:=Low(TpvScene3D.TDoubleSided) to High(TpvScene3D.TDoubleSided) do begin
     FreeAndNil(fVulkanGraphicsPipelines[DepthPrePass,AlphaMode,PrimitiveTopology,DoubleSided]);
    end;
   end;
  end;
 end;

 for DepthPrePass:=false to fInstance.Renderer.UseDepthPrepass do begin

  for AlphaMode:=Low(TpvScene3D.TMaterial.TAlphaMode) to High(TpvScene3D.TMaterial.TAlphaMode) do begin

   for PrimitiveTopology:=Low(TpvScene3D.TPrimitiveTopology) to High(TpvScene3D.TPrimitiveTopology) do begin

    for DoubleSided:=Low(TpvScene3D.TDoubleSided) to High(TpvScene3D.TDoubleSided) do begin

     VulkanGraphicsPipeline:=TpvVulkanGraphicsPipeline.Create(pvApplication.VulkanDevice,
                                                              pvApplication.VulkanPipelineCache,
                                                              0,
                                                              [],
                                                              fVulkanPipelineLayout,
                                                              fVulkanRenderPass,
                                                              VulkanRenderPassSubpassIndex,
                                                              nil,
                                                              0);

     try

      VulkanGraphicsPipeline.AddStage(fVulkanPipelineShaderStageMeshVertex);
      if DepthPrePass then begin
       if AlphaMode=TpvScene3D.TMaterial.TAlphaMode.Mask then begin
        VulkanGraphicsPipeline.AddStage(fVulkanPipelineShaderStageMeshDepthMaskedFragment);
       end else begin
        VulkanGraphicsPipeline.AddStage(fVulkanPipelineShaderStageMeshDepthFragment);
       end;
      end else begin
       if AlphaMode=TpvScene3D.TMaterial.TAlphaMode.Mask then begin
        VulkanGraphicsPipeline.AddStage(fVulkanPipelineShaderStageMeshMaskedFragment);
       end else begin
        VulkanGraphicsPipeline.AddStage(fVulkanPipelineShaderStageMeshFragment);
       end;
      end;

      VulkanGraphicsPipeline.InputAssemblyState.Topology:=TVkPrimitiveTopology(PrimitiveTopology);
      VulkanGraphicsPipeline.InputAssemblyState.PrimitiveRestartEnable:=false;

      fInstance.Renderer.Scene3D.InitializeGraphicsPipeline(VulkanGraphicsPipeline);

      VulkanGraphicsPipeline.ViewPortState.AddViewPort(0.0,0.0,fInstance.Width,fInstance.Height,0.0,1.0);
      VulkanGraphicsPipeline.ViewPortState.AddScissor(0,0,fInstance.Width,fInstance.Height);

      VulkanGraphicsPipeline.RasterizationState.DepthClampEnable:=false;
      VulkanGraphicsPipeline.RasterizationState.RasterizerDiscardEnable:=false;
      VulkanGraphicsPipeline.RasterizationState.PolygonMode:=VK_POLYGON_MODE_FILL;
      if DoubleSided then begin
       VulkanGraphicsPipeline.RasterizationState.CullMode:=TVkCullModeFlags(VK_CULL_MODE_NONE);
      end else begin
       VulkanGraphicsPipeline.RasterizationState.CullMode:=TVkCullModeFlags(VK_CULL_MODE_BACK_BIT);
      end;
      VulkanGraphicsPipeline.RasterizationState.FrontFace:=VK_FRONT_FACE_COUNTER_CLOCKWISE;
      VulkanGraphicsPipeline.RasterizationState.DepthBiasEnable:=false;
      VulkanGraphicsPipeline.RasterizationState.DepthBiasConstantFactor:=0.0;
      VulkanGraphicsPipeline.RasterizationState.DepthBiasClamp:=0.0;
      VulkanGraphicsPipeline.RasterizationState.DepthBiasSlopeFactor:=0.0;
      VulkanGraphicsPipeline.RasterizationState.LineWidth:=1.0;

      VulkanGraphicsPipeline.MultisampleState.RasterizationSamples:=fInstance.Renderer.SurfaceSampleCountFlagBits;
      if (not DepthPrePass) and
         (AlphaMode=TpvScene3D.TMaterial.TAlphaMode.Mask) and
         (VulkanGraphicsPipeline.MultisampleState.RasterizationSamples<>VK_SAMPLE_COUNT_1_BIT) then begin
       VulkanGraphicsPipeline.MultisampleState.SampleShadingEnable:=true;
       VulkanGraphicsPipeline.MultisampleState.MinSampleShading:=1.0;
       VulkanGraphicsPipeline.MultisampleState.CountSampleMasks:=0;
       VulkanGraphicsPipeline.MultisampleState.AlphaToCoverageEnable:=true;
       VulkanGraphicsPipeline.MultisampleState.AlphaToOneEnable:=false;
       VulkanGraphicsPipeline.MultisampleState.AddSampleMask((1 shl fInstance.Renderer.CountSurfaceMSAASamples)-1);
      end else begin
       VulkanGraphicsPipeline.MultisampleState.SampleShadingEnable:=false;
       VulkanGraphicsPipeline.MultisampleState.MinSampleShading:=0.0;
       VulkanGraphicsPipeline.MultisampleState.CountSampleMasks:=0;
       VulkanGraphicsPipeline.MultisampleState.AlphaToCoverageEnable:=false;
       VulkanGraphicsPipeline.MultisampleState.AlphaToOneEnable:=false;
      end;

      VulkanGraphicsPipeline.ColorBlendState.LogicOpEnable:=false;
      VulkanGraphicsPipeline.ColorBlendState.LogicOp:=VK_LOGIC_OP_COPY;
      VulkanGraphicsPipeline.ColorBlendState.BlendConstants[0]:=0.0;
      VulkanGraphicsPipeline.ColorBlendState.BlendConstants[1]:=0.0;
      VulkanGraphicsPipeline.ColorBlendState.BlendConstants[2]:=0.0;
      VulkanGraphicsPipeline.ColorBlendState.BlendConstants[3]:=0.0;
      if DepthPrePass then begin
       VulkanGraphicsPipeline.ColorBlendState.AddColorBlendAttachmentState(false,
                                                                           VK_BLEND_FACTOR_ZERO,
                                                                           VK_BLEND_FACTOR_ZERO,
                                                                           VK_BLEND_OP_ADD,
                                                                           VK_BLEND_FACTOR_ZERO,
                                                                           VK_BLEND_FACTOR_ZERO,
                                                                           VK_BLEND_OP_ADD,
                                                                           0);
      end else begin
       if ((VulkanGraphicsPipeline.MultisampleState.RasterizationSamples<>VK_SAMPLE_COUNT_1_BIT) and
           (AlphaMode=TpvScene3D.TMaterial.TAlphaMode.Mask)) or
          (AlphaMode=TpvScene3D.TMaterial.TAlphaMode.Blend) then begin
        VulkanGraphicsPipeline.ColorBlendState.AddColorBlendAttachmentState(true,
                                                                            VK_BLEND_FACTOR_SRC_ALPHA,
                                                                            VK_BLEND_FACTOR_ONE_MINUS_SRC_ALPHA,
                                                                            VK_BLEND_OP_ADD,
                                                                            VK_BLEND_FACTOR_ONE,
                                                                            VK_BLEND_FACTOR_ONE_MINUS_SRC_ALPHA,
                                                                            VK_BLEND_OP_ADD,
                                                                            TVkColorComponentFlags(VK_COLOR_COMPONENT_R_BIT) or
                                                                            TVkColorComponentFlags(VK_COLOR_COMPONENT_G_BIT) or
                                                                            TVkColorComponentFlags(VK_COLOR_COMPONENT_B_BIT) or
                                                                            TVkColorComponentFlags(VK_COLOR_COMPONENT_A_BIT));
       end else begin
        VulkanGraphicsPipeline.ColorBlendState.AddColorBlendAttachmentState(false,
                                                                            VK_BLEND_FACTOR_ZERO,
                                                                            VK_BLEND_FACTOR_ZERO,
                                                                            VK_BLEND_OP_ADD,
                                                                            VK_BLEND_FACTOR_ZERO,
                                                                            VK_BLEND_FACTOR_ZERO,
                                                                            VK_BLEND_OP_ADD,
                                                                            TVkColorComponentFlags(VK_COLOR_COMPONENT_R_BIT) or
                                                                            TVkColorComponentFlags(VK_COLOR_COMPONENT_G_BIT) or
                                                                            TVkColorComponentFlags(VK_COLOR_COMPONENT_B_BIT) or
                                                                            TVkColorComponentFlags(VK_COLOR_COMPONENT_A_BIT));
       end;
      end;

      VulkanGraphicsPipeline.DepthStencilState.DepthTestEnable:=true;
      VulkanGraphicsPipeline.DepthStencilState.DepthWriteEnable:=AlphaMode<>TpvScene3D.TMaterial.TAlphaMode.Blend;
      if fInstance.ZFar<0.0 then begin
       VulkanGraphicsPipeline.DepthStencilState.DepthCompareOp:=VK_COMPARE_OP_GREATER_OR_EQUAL;
       end else begin
       VulkanGraphicsPipeline.DepthStencilState.DepthCompareOp:=VK_COMPARE_OP_LESS_OR_EQUAL;
      end;
      VulkanGraphicsPipeline.DepthStencilState.DepthBoundsTestEnable:=false;
      VulkanGraphicsPipeline.DepthStencilState.StencilTestEnable:=false;

      VulkanGraphicsPipeline.Initialize;

      VulkanGraphicsPipeline.FreeMemory;

     finally
      fVulkanGraphicsPipelines[DepthPrePass,AlphaMode,PrimitiveTopology,DoubleSided]:=VulkanGraphicsPipeline;
     end;

    end;

   end;

  end;

 end;

 fSkyBox.AllocateResources(fVulkanRenderPass,
                           fInstance.Width,
                           fInstance.Height,
                           fInstance.Renderer.SurfaceSampleCountFlagBits);

end;

procedure TpvScene3DRendererInstancePassesForwardRenderPass.BeforeDestroySwapChain;
var Index:TpvSizeInt;
    DepthPrePass:boolean;
    AlphaMode:TpvScene3D.TMaterial.TAlphaMode;
    PrimitiveTopology:TpvScene3D.TPrimitiveTopology;
    DoubleSided:TpvScene3D.TDoubleSided;
begin
 fSkyBox.ReleaseResources;
 for DepthPrePass:=false to fInstance.Renderer.UseDepthPrepass do begin
  for AlphaMode:=Low(TpvScene3D.TMaterial.TAlphaMode) to High(TpvScene3D.TMaterial.TAlphaMode) do begin
   for PrimitiveTopology:=Low(TpvScene3D.TPrimitiveTopology) to High(TpvScene3D.TPrimitiveTopology) do begin
    for DoubleSided:=Low(TpvScene3D.TDoubleSided) to High(TpvScene3D.TDoubleSided) do begin
     FreeAndNil(fVulkanGraphicsPipelines[DepthPrePass,AlphaMode,PrimitiveTopology,DoubleSided]);
    end;
   end;
  end;
 end;
 FreeAndNil(fVulkanPipelineLayout);
 for Index:=0 to fInstance.Renderer.CountInFlightFrames-1 do begin
  FreeAndNil(fGlobalVulkanDescriptorSets[Index]);
 end;
 FreeAndNil(fGlobalVulkanDescriptorPool);
 FreeAndNil(fGlobalVulkanDescriptorSetLayout);
 inherited BeforeDestroySwapChain;
end;

procedure TpvScene3DRendererInstancePassesForwardRenderPass.Update(const aUpdateInFlightFrameIndex,aUpdateFrameIndex:TpvSizeInt);
begin
 inherited Update(aUpdateInFlightFrameIndex,aUpdateFrameIndex);
end;

procedure TpvScene3DRendererInstancePassesForwardRenderPass.OnSetRenderPassResources(const aCommandBuffer:TpvVulkanCommandBuffer;
                                                                  const aPipelineLayout:TpvVulkanPipelineLayout;
                                                                  const aRenderPassIndex:TpvSizeInt;
                                                                  const aPreviousInFlightFrameIndex:TpvSizeInt;
                                                                  const aInFlightFrameIndex:TpvSizeInt);
begin
 if not fOnSetRenderPassResourcesDone then begin
  fOnSetRenderPassResourcesDone:=true;
  aCommandBuffer.CmdBindDescriptorSets(VK_PIPELINE_BIND_POINT_GRAPHICS,
                                       fVulkanPipelineLayout.Handle,
                                       1,
                                       1,
                                       @fGlobalVulkanDescriptorSets[aInFlightFrameIndex].Handle,
                                       0,
                                       nil);
 end;
end;

procedure TpvScene3DRendererInstancePassesForwardRenderPass.Execute(const aCommandBuffer:TpvVulkanCommandBuffer;
                                                 const aInFlightFrameIndex,aFrameIndex:TpvSizeInt);
var InFlightFrameState:TpvScene3DRendererInstance.PInFlightFrameState;
begin
 inherited Execute(aCommandBuffer,aInFlightFrameIndex,aFrameIndex);

 InFlightFrameState:=@fInstance.InFlightFrameStates^[aInFlightFrameIndex];

 if InFlightFrameState^.Ready then begin

{}fSkyBox.Draw(aInFlightFrameIndex,
               InFlightFrameState^.FinalViewIndex,
               InFlightFrameState^.CountViews,
               aCommandBuffer);//{}

  if true then begin

   fOnSetRenderPassResourcesDone:=false;

(* if fInstance.Renderer.UseDepthPrepass then begin

    fInstance.Renderer.Scene3D.Draw(fVulkanGraphicsPipelines[true,TpvScene3D.TMaterial.TAlphaMode.Opaque],
                          -1,
                          aInFlightFrameIndex,
                          0,
                          InFlightFrameState^.FinalViewIndex,
                          InFlightFrameState^.CountViews,
                          fFrameGraph.DrawFrameIndex,
                          aCommandBuffer,
                          fVulkanPipelineLayout,
                          OnSetRenderPassResources,
                          [TpvScene3D.TMaterial.TAlphaMode.Opaque]);

 {  if fInstance.Renderer.SurfaceSampleCountFlagBits=VK_SAMPLE_COUNT_1_BIT then begin
     fInstance.Renderer.Scene3D.Draw(fVulkanGraphicsPipelines[true,TpvScene3D.TMaterial.TAlphaMode.Mask],
                           aInFlightFrameIndex,
                           0,
                           InFlightFrameState^.FinalViewIndex,
                           InFlightFrameState^.CountViews,
                           fFrameGraph.DrawFrameIndex,
                           aCommandBuffer,
                           fVulkanPipelineLayout,
                           OnSetRenderPassResources,
                           [TpvScene3D.TMaterial.TAlphaMode.Mask]);
    end;}

   end;   *)

   fInstance.Renderer.Scene3D.Draw(fVulkanGraphicsPipelines[false,TpvScene3D.TMaterial.TAlphaMode.Opaque],
                         -1,
                         aInFlightFrameIndex,
                         0,
                         InFlightFrameState^.FinalViewIndex,
                         InFlightFrameState^.CountViews,
                         fFrameGraph.DrawFrameIndex,
                         aCommandBuffer,
                         fVulkanPipelineLayout,
                         OnSetRenderPassResources,
                         [TpvScene3D.TMaterial.TAlphaMode.Opaque]);

  if ((fInstance.Renderer.TransparencyMode=TpvScene3DRendererTransparencyMode.Direct) and not fInstance.Renderer.Scene3D.HasTransmission) or not (fInstance.Renderer.UseOITAlphaTest or fInstance.Renderer.Scene3D.HasTransmission) then begin
   fInstance.Renderer.Scene3D.Draw(fVulkanGraphicsPipelines[false,TpvScene3D.TMaterial.TAlphaMode.Mask],
                         -1,
                         aInFlightFrameIndex,
                         0,
                         InFlightFrameState^.FinalViewIndex,
                         InFlightFrameState^.CountViews,
                         fFrameGraph.DrawFrameIndex,
                         aCommandBuffer,
                         fVulkanPipelineLayout,
                         OnSetRenderPassResources,
                         [TpvScene3D.TMaterial.TAlphaMode.Mask]);
  end;

 { if fInstance.Renderer.UseDepthPrepass then begin

    fInstance.Renderer.Scene3D.Draw(fVulkanGraphicsPipelines[true,TpvScene3D.TMaterial.TAlphaMode.Mask],
                          -1,
                          aInFlightFrameIndex,
                          0,
                          InFlightFrameState^.FinalViewIndex,
                          InFlightFrameState^.CountViews,
                          fFrameGraph.DrawFrameIndex,
                          aCommandBuffer,
                          fVulkanPipelineLayout,
                          OnSetRenderPassResources,
                          [TpvScene3D.TMaterial.TAlphaMode.Mask]);

   end;}

  end;

 end;

end;

end.