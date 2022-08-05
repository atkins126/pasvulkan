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
unit PasVulkan.Scene3D.Renderer.Passes.DitheringRenderPass;
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
     PasVulkan.Scene3D.Renderer.Instance;

type { TpvScene3DRendererInstancePassesDitheringRenderPass }
      TpvScene3DRendererInstancePassesDitheringRenderPass=class(TpvFrameGraph.TRenderPass)
       private
        fInstance:TpvScene3DRendererInstance;
        fVulkanRenderPass:TpvVulkanRenderPass;
        fResourceColor:TpvFrameGraph.TPass.TUsedImageResource;
        fResourceSurface:TpvFrameGraph.TPass.TUsedImageResource;
        fVulkanTransferCommandBuffer:TpvVulkanCommandBuffer;
        fVulkanTransferCommandBufferFence:TpvVulkanFence;
        fVulkanVertexShaderModule:TpvVulkanShaderModule;
        fVulkanFragmentShaderModule:TpvVulkanShaderModule;
        fVulkanPipelineShaderStageVertex:TpvVulkanPipelineShaderStage;
        fVulkanPipelineShaderStageFragment:TpvVulkanPipelineShaderStage;
        fVulkanGraphicsPipeline:TpvVulkanGraphicsPipeline;
        fVulkanSampler:TpvVulkanSampler;
        fVulkanDescriptorPool:TpvVulkanDescriptorPool;
        fVulkanDescriptorSetLayout:TpvVulkanDescriptorSetLayout;
        fVulkanImageViews:array[0..MaxInFlightFrames-1] of TpvVulkanImageView;
        fVulkanDescriptorSets:array[0..MaxInFlightFrames-1] of TpvVulkanDescriptorSet;
        fVulkanPipelineLayout:TpvVulkanPipelineLayout;
       public
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

{ TpvScene3DRendererInstancePassesDitheringRenderPass }


constructor TpvScene3DRendererInstancePassesDitheringRenderPass.Create(const aFrameGraph:TpvFrameGraph;const aInstance:TpvScene3DRendererInstance);
begin

 inherited Create(aFrameGraph);

 fInstance:=aInstance;

 Name:='Dithering';

 MultiviewMask:=fInstance.SurfaceMultiviewMask;

 Queue:=aFrameGraph.UniversalQueue;

//SeparatePhysicalPass:=true;

//SeparateCommandBuffer:=true;

 Size:=TpvFrameGraph.TImageSize.Create(TpvFrameGraph.TImageSize.TKind.SurfaceDependent,
                                       1.0,
                                       1.0,
                                       1.0,
                                       fInstance.CountSurfaceViews);

 fResourceColor:=AddImageInput('resourcetype_color_antialiasing',
                               'resource_antialiasing_color',
                               VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
                               [TpvFrameGraph.TResourceTransition.TFlag.Attachment]
                              );

 if assigned(fInstance.VirtualReality) then begin
  fResourceSurface:=AddImageOutput('resourcetype_output_color',
                                   'resource_output',
                                   VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
                                   TpvFrameGraph.TLoadOp.Create(TpvFrameGraph.TLoadOp.TKind.Clear,
                                                                TpvVector4.InlineableCreate(0.0,0.0,0.0,1.0)),
                                   [TpvFrameGraph.TResourceTransition.TFlag.Attachment],
                                   TpvFrameGraph.TResourceInstanceType.Default,
                                   fInstance.ExternalOutputImageData
                                  );
 end else begin
  fResourceSurface:=AddImageOutput('resourcetype_output_color',
                                   'resource_output',
                                   VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
                                   TpvFrameGraph.TLoadOp.Create(TpvFrameGraph.TLoadOp.TKind.Clear,
                                                                TpvVector4.InlineableCreate(0.0,0.0,0.0,1.0)),
                                   [TpvFrameGraph.TResourceTransition.TFlag.Attachment]
                                  );
 end;

end;

destructor TpvScene3DRendererInstancePassesDitheringRenderPass.Destroy;
begin
 inherited Destroy;
end;

procedure TpvScene3DRendererInstancePassesDitheringRenderPass.Show;
var Stream:TStream;
begin

 inherited Show;

 fVulkanTransferCommandBuffer:=TpvVulkanCommandBuffer.Create(FrameGraph.TransferQueue.CommandPool,VK_COMMAND_BUFFER_LEVEL_PRIMARY);

 fVulkanTransferCommandBufferFence:=TpvVulkanFence.Create(pvApplication.VulkanDevice);

 Stream:=pvApplication.Assets.GetAssetStream('shaders/fullscreen_vert.spv');
 try
  fVulkanVertexShaderModule:=TpvVulkanShaderModule.Create(pvApplication.VulkanDevice,Stream);
 finally
  Stream.Free;
 end;

 Stream:=pvApplication.Assets.GetAssetStream('shaders/dithering_frag.spv');
 try
  fVulkanFragmentShaderModule:=TpvVulkanShaderModule.Create(pvApplication.VulkanDevice,Stream);
 finally
  Stream.Free;
 end;

 fVulkanPipelineShaderStageVertex:=TpvVulkanPipelineShaderStage.Create(VK_SHADER_STAGE_VERTEX_BIT,fVulkanVertexShaderModule,'main');

 fVulkanPipelineShaderStageFragment:=TpvVulkanPipelineShaderStage.Create(VK_SHADER_STAGE_FRAGMENT_BIT,fVulkanFragmentShaderModule,'main');

 fVulkanGraphicsPipeline:=nil;

 fVulkanSampler:=TpvVulkanSampler.Create(pvApplication.VulkanDevice,
                                         TVkFilter.VK_FILTER_LINEAR,
                                         TVkFilter.VK_FILTER_LINEAR,
                                         TVkSamplerMipmapMode.VK_SAMPLER_MIPMAP_MODE_LINEAR,
                                         VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE,
                                         VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE,
                                         VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE,
                                         0.0,
                                         false,
                                         0.0,
                                         false,
                                         VK_COMPARE_OP_ALWAYS,
                                         0.0,
                                         0.0,
                                         VK_BORDER_COLOR_FLOAT_OPAQUE_BLACK,
                                         false);

end;

procedure TpvScene3DRendererInstancePassesDitheringRenderPass.Hide;
begin
 FreeAndNil(fVulkanSampler);
 FreeAndNil(fVulkanPipelineShaderStageVertex);
 FreeAndNil(fVulkanPipelineShaderStageFragment);
 FreeAndNil(fVulkanFragmentShaderModule);
 FreeAndNil(fVulkanVertexShaderModule);
 FreeAndNil(fVulkanTransferCommandBufferFence);
 FreeAndNil(fVulkanTransferCommandBuffer);
 inherited Hide;
end;

procedure TpvScene3DRendererInstancePassesDitheringRenderPass.AfterCreateSwapChain;
var InFlightFrameIndex:TpvSizeInt;
begin
 inherited AfterCreateSwapChain;

 fVulkanRenderPass:=VulkanRenderPass;

 fVulkanDescriptorPool:=TpvVulkanDescriptorPool.Create(pvApplication.VulkanDevice,
                                                       TVkDescriptorPoolCreateFlags(VK_DESCRIPTOR_POOL_CREATE_FREE_DESCRIPTOR_SET_BIT),
                                                       fInstance.Renderer.CountInFlightFrames);
 fVulkanDescriptorPool.AddDescriptorPoolSize(VK_DESCRIPTOR_TYPE_INPUT_ATTACHMENT,fInstance.Renderer.CountInFlightFrames);
 fVulkanDescriptorPool.Initialize;

 fVulkanDescriptorSetLayout:=TpvVulkanDescriptorSetLayout.Create(pvApplication.VulkanDevice);
 fVulkanDescriptorSetLayout.AddBinding(0,
                                       VK_DESCRIPTOR_TYPE_INPUT_ATTACHMENT,
                                       1,
                                       TVkShaderStageFlags(VK_SHADER_STAGE_FRAGMENT_BIT),
                                       []);
 fVulkanDescriptorSetLayout.Initialize;

 for InFlightFrameIndex:=0 to FrameGraph.CountInFlightFrames-1 do begin
  fVulkanImageViews[InFlightFrameIndex]:=TpvVulkanImageView.Create(pvApplication.VulkanDevice,
                                                                   fResourceColor.VulkanImages[InFlightFrameIndex],
                                                                   VK_IMAGE_VIEW_TYPE_2D_ARRAY,
                                                                   TpvFrameGraph.TImageResourceType(fResourceColor.ResourceType).Format,
                                                                   VK_COMPONENT_SWIZZLE_IDENTITY,
                                                                   VK_COMPONENT_SWIZZLE_IDENTITY,
                                                                   VK_COMPONENT_SWIZZLE_IDENTITY,
                                                                   VK_COMPONENT_SWIZZLE_IDENTITY,
                                                                   TVkImageAspectFlags(VK_IMAGE_ASPECT_COLOR_BIT),
                                                                   0,
                                                                   1,
                                                                   0,
                                                                   fInstance.CountSurfaceViews
                                                                  );
  fVulkanDescriptorSets[InFlightFrameIndex]:=TpvVulkanDescriptorSet.Create(fVulkanDescriptorPool,
                                                                           fVulkanDescriptorSetLayout);
  fVulkanDescriptorSets[InFlightFrameIndex].WriteToDescriptorSet(0,
                                                                 0,
                                                                 1,
                                                                 TVkDescriptorType(VK_DESCRIPTOR_TYPE_INPUT_ATTACHMENT),
                                                                 [TVkDescriptorImageInfo.Create(VK_NULL_HANDLE,
                                                                                                fResourceColor.VulkanImageViews[InFlightFrameIndex].Handle,
                                                                                                fResourceColor.ResourceTransition.Layout)],// TVkImageLayout(VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL))],
                                                                 [],
                                                                 [],
                                                                 false
                                                                );
  fVulkanDescriptorSets[InFlightFrameIndex].Flush;
 end;

 fVulkanPipelineLayout:=TpvVulkanPipelineLayout.Create(pvApplication.VulkanDevice);
 fVulkanPipelineLayout.AddDescriptorSetLayout(fVulkanDescriptorSetLayout);
 fVulkanPipelineLayout.AddPushConstantRange(TVkShaderStageFlags(VK_SHADER_STAGE_FRAGMENT_BIT),0,SizeOf(TpvInt32));
 fVulkanPipelineLayout.Initialize;

 fVulkanGraphicsPipeline:=TpvVulkanGraphicsPipeline.Create(pvApplication.VulkanDevice,
                                                           pvApplication.VulkanPipelineCache,
                                                           0,
                                                           [],
                                                           fVulkanPipelineLayout,
                                                           fVulkanRenderPass,
                                                           VulkanRenderPassSubpassIndex,
                                                           nil,
                                                           0);

 fVulkanGraphicsPipeline.AddStage(fVulkanPipelineShaderStageVertex);
 fVulkanGraphicsPipeline.AddStage(fVulkanPipelineShaderStageFragment);

 fVulkanGraphicsPipeline.InputAssemblyState.Topology:=VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST;
 fVulkanGraphicsPipeline.InputAssemblyState.PrimitiveRestartEnable:=false;

 fVulkanGraphicsPipeline.ViewPortState.AddViewPort(0.0,0.0,fInstance.Width,fInstance.Height,0.0,1.0);
 fVulkanGraphicsPipeline.ViewPortState.AddScissor(0,0,fInstance.Width,fInstance.Height);

 fVulkanGraphicsPipeline.RasterizationState.DepthClampEnable:=false;
 fVulkanGraphicsPipeline.RasterizationState.RasterizerDiscardEnable:=false;
 fVulkanGraphicsPipeline.RasterizationState.PolygonMode:=VK_POLYGON_MODE_FILL;
 fVulkanGraphicsPipeline.RasterizationState.CullMode:=TVkCullModeFlags(VK_CULL_MODE_NONE);
 fVulkanGraphicsPipeline.RasterizationState.FrontFace:=VK_FRONT_FACE_CLOCKWISE;
 fVulkanGraphicsPipeline.RasterizationState.DepthBiasEnable:=false;
 fVulkanGraphicsPipeline.RasterizationState.DepthBiasConstantFactor:=0.0;
 fVulkanGraphicsPipeline.RasterizationState.DepthBiasClamp:=0.0;
 fVulkanGraphicsPipeline.RasterizationState.DepthBiasSlopeFactor:=0.0;
 fVulkanGraphicsPipeline.RasterizationState.LineWidth:=1.0;

 fVulkanGraphicsPipeline.MultisampleState.RasterizationSamples:=VK_SAMPLE_COUNT_1_BIT;
 fVulkanGraphicsPipeline.MultisampleState.SampleShadingEnable:=false;
 fVulkanGraphicsPipeline.MultisampleState.MinSampleShading:=0.0;
 fVulkanGraphicsPipeline.MultisampleState.CountSampleMasks:=0;
 fVulkanGraphicsPipeline.MultisampleState.AlphaToCoverageEnable:=false;
 fVulkanGraphicsPipeline.MultisampleState.AlphaToOneEnable:=false;

 fVulkanGraphicsPipeline.ColorBlendState.LogicOpEnable:=false;
 fVulkanGraphicsPipeline.ColorBlendState.LogicOp:=VK_LOGIC_OP_COPY;
 fVulkanGraphicsPipeline.ColorBlendState.BlendConstants[0]:=0.0;
 fVulkanGraphicsPipeline.ColorBlendState.BlendConstants[1]:=0.0;
 fVulkanGraphicsPipeline.ColorBlendState.BlendConstants[2]:=0.0;
 fVulkanGraphicsPipeline.ColorBlendState.BlendConstants[3]:=0.0;
 fVulkanGraphicsPipeline.ColorBlendState.AddColorBlendAttachmentState(false,
                                                                      VK_BLEND_FACTOR_SRC_ALPHA,
                                                                      VK_BLEND_FACTOR_DST_ALPHA,
                                                                      VK_BLEND_OP_ADD,
                                                                      VK_BLEND_FACTOR_ONE,
                                                                      VK_BLEND_FACTOR_ZERO,
                                                                      VK_BLEND_OP_ADD,
                                                                      TVkColorComponentFlags(VK_COLOR_COMPONENT_R_BIT) or
                                                                      TVkColorComponentFlags(VK_COLOR_COMPONENT_G_BIT) or
                                                                      TVkColorComponentFlags(VK_COLOR_COMPONENT_B_BIT) or
                                                                      TVkColorComponentFlags(VK_COLOR_COMPONENT_A_BIT));

 fVulkanGraphicsPipeline.DepthStencilState.DepthTestEnable:=true;
 fVulkanGraphicsPipeline.DepthStencilState.DepthWriteEnable:=true;
 fVulkanGraphicsPipeline.DepthStencilState.DepthCompareOp:=VK_COMPARE_OP_ALWAYS;
 fVulkanGraphicsPipeline.DepthStencilState.DepthBoundsTestEnable:=false;
 fVulkanGraphicsPipeline.DepthStencilState.StencilTestEnable:=false;

 fVulkanGraphicsPipeline.Initialize;

 fVulkanGraphicsPipeline.FreeMemory;

end;

procedure TpvScene3DRendererInstancePassesDitheringRenderPass.BeforeDestroySwapChain;
var InFlightFrameIndex:TpvSizeInt;
begin

 FreeAndNil(fVulkanGraphicsPipeline);

 FreeAndNil(fVulkanPipelineLayout);

 for InFlightFrameIndex:=0 to FrameGraph.CountInFlightFrames-1 do begin
  FreeAndNil(fVulkanDescriptorSets[InFlightFrameIndex]);
  FreeAndNil(fVulkanImageViews[InFlightFrameIndex]);
 end;

 FreeAndNil(fVulkanDescriptorSetLayout);

 FreeAndNil(fVulkanDescriptorPool);

 fVulkanRenderPass:=nil;

 inherited BeforeDestroySwapChain;
end;

procedure TpvScene3DRendererInstancePassesDitheringRenderPass.Update(const aUpdateInFlightFrameIndex,aUpdateFrameIndex:TpvSizeInt);
begin
 inherited Update(aUpdateInFlightFrameIndex,aUpdateFrameIndex);
end;

procedure TpvScene3DRendererInstancePassesDitheringRenderPass.Execute(const aCommandBuffer:TpvVulkanCommandBuffer;const aInFlightFrameIndex,aFrameIndex:TpvSizeInt);
var FrameCounter:TpvInt32;
begin
 inherited Execute(aCommandBuffer,aInFlightFrameIndex,aFrameIndex);
 FrameCounter:=TpvInt32(FrameGraph.DrawFrameIndex);
 aCommandBuffer.CmdBindDescriptorSets(VK_PIPELINE_BIND_POINT_GRAPHICS,
                                      fVulkanPipelineLayout.Handle,
                                      0,
                                      1,
                                      @fVulkanDescriptorSets[aInFlightFrameIndex].Handle,0,nil);
 aCommandBuffer.CmdPushConstants(fVulkanPipelineLayout.Handle,TVkShaderStageFlags(TVkShaderStageFlagBits.VK_SHADER_STAGE_FRAGMENT_BIT),0,SizeOf(TpvInt32),@FrameCounter);
 aCommandBuffer.CmdBindPipeline(VK_PIPELINE_BIND_POINT_GRAPHICS,fVulkanGraphicsPipeline.Handle);
 aCommandBuffer.CmdDraw(3,1,0,0);
end;

end.