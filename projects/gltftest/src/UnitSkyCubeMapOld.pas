unit UnitSkyCubeMap;
{$ifdef fpc}
 {$mode delphi}
 {$ifdef cpu386}
  {$asmmode intel}
 {$endif}
 {$ifdef cpuamd64}
  {$asmmode intel}
 {$endif}
{$else}
 {$ifdef conditionalexpressions}
  {$if CompilerVersion>=24.0}
   {$legacyifend on}
  {$ifend}
 {$endif}
{$endif}
{$if defined(Win32) or defined(Win64)}
 {$define Windows}
{$ifend}

interface

uses SysUtils,
     Classes,
     Math,
     Vulkan,
     PasVulkan.Types,
     PasVulkan.Math,
     PasVulkan.Framework,
     PasVulkan.Application;

type { TSkyCubeMap }
     TSkyCubeMap=class
      public
       const Width=512;
             Height=512;
             ImageFormat=TVkFormat(VK_FORMAT_R16G16B16A16_SFLOAT);
             LightDirection:TpvVector4=(x:0.333333333333;y:-0.666666666666;z:-0.666666666666;w:0.0);
      private
       fVertexShaderModule:TpvVulkanShaderModule;
       fFragmentShaderModule:TpvVulkanShaderModule;
       fVulkanPipelineShaderStageVertex:TpvVulkanPipelineShaderStage;
       fVulkanPipelineShaderStageFragment:TpvVulkanPipelineShaderStage;
       fVulkanImage:TpvVulkanImage;
       fVulkanSampler:TpvVulkanSampler;
       fVulkanImageView:TpvVulkanImageView;
       fMemoryBlock:TpvVulkanDeviceMemoryBlock;
       fDescriptorImageInfo:TVkDescriptorImageInfo;
      public

       constructor Create;

       destructor Destroy; override;

      published

       property VulkanImage:TpvVulkanImage read fVulkanImage;

       property VulkanSampler:TpvVulkanSampler read fVulkanSampler;

       property VulkanImageView:TpvVulkanImageView read fVulkanImageView;

      public

       property DescriptorImageInfo:TVkDescriptorImageInfo read fDescriptorImageInfo;

     end;

implementation

{ TSkyCubeMap }

constructor TSkyCubeMap.Create;
var Index,FaceIndex,MipMaps:TpvSizeInt;
    Stream:TStream;
    MemoryRequirements:TVkMemoryRequirements;
    RequiresDedicatedAllocation,
    PrefersDedicatedAllocation:boolean;
    MemoryBlockFlags:TpvVulkanDeviceMemoryBlockFlags;
    ImageSubresourceRange:TVkImageSubresourceRange;
    Queue:TpvVulkanQueue;
    CommandPool:TpvVulkanCommandPool;
    CommandBuffer:TpvVulkanCommandBuffer;
    Fence:TpvVulkanFence;
    ImageView:TpvVulkanImageView;
    FrameBuffer:TpvVulkanFrameBuffer;
    RenderPass:TpvVulkanRenderPass;
    FrameBufferColorAttachment:TpvVulkanFrameBufferAttachment;
    PipelineLayout:TpvVulkanPipelineLayout;
    Pipeline:TpvVulkanGraphicsPipeline;
    ImageBlit:TVkImageBlit;
    ImageMemoryBarrier:TVkImageMemoryBarrier;
begin
 inherited Create;

 MipMaps:=IntLog2(Max(Width,Height))+1;

 Stream:=pvApplication.Assets.GetAssetStream('shaders/cubemap_vert.spv');
 try
  fVertexShaderModule:=TpvVulkanShaderModule.Create(pvApplication.VulkanDevice,Stream);
 finally
  Stream.Free;
 end;

 case pvApplication.VulkanDevice.PhysicalDevice.Properties.vendorID of
  TVkUInt32(TpvVulkanVendorID.NVIDIA),TVkUInt32(TpvVulkanVendorID.AMD):begin
   Stream:=pvApplication.Assets.GetAssetStream('shaders/cubemap_sky_frag.spv');
  end;
  else begin
   Stream:=pvApplication.Assets.GetAssetStream('shaders/cubemap_sky_fast_frag.spv');
  end;
 end;
 try
  fFragmentShaderModule:=TpvVulkanShaderModule.Create(pvApplication.VulkanDevice,Stream);
 finally
  Stream.Free;
 end;

 fVulkanPipelineShaderStageVertex:=TpvVulkanPipelineShaderStage.Create(VK_SHADER_STAGE_VERTEX_BIT,fVertexShaderModule,'main');

 fVulkanPipelineShaderStageFragment:=TpvVulkanPipelineShaderStage.Create(VK_SHADER_STAGE_FRAGMENT_BIT,fFragmentShaderModule,'main');

 fVulkanImage:=TpvVulkanImage.Create(pvApplication.VulkanDevice,
                                     TVkImageCreateFlags(VK_IMAGE_CREATE_CUBE_COMPATIBLE_BIT),
                                     VK_IMAGE_TYPE_2D,
                                     ImageFormat,
                                     Width,
                                     Height,
                                     1,
                                     MipMaps,
                                     6,
                                     VK_SAMPLE_COUNT_1_BIT,
                                     VK_IMAGE_TILING_OPTIMAL,
                                     TVkImageUsageFlags(VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT) or
                                     TVkImageUsageFlags(VK_IMAGE_USAGE_TRANSFER_SRC_BIT) or
                                     TVkImageUsageFlags(VK_IMAGE_USAGE_TRANSFER_DST_BIT) or
                                     TVkImageUsageFlags(VK_IMAGE_USAGE_SAMPLED_BIT),
                                     VK_SHARING_MODE_EXCLUSIVE,
                                     0,
                                     nil,
                                     VK_IMAGE_LAYOUT_UNDEFINED
                                    );

 MemoryRequirements:=pvApplication.VulkanDevice.MemoryManager.GetImageMemoryRequirements(fVulkanImage.Handle,
                                                                                         RequiresDedicatedAllocation,
                                                                                         PrefersDedicatedAllocation);

 MemoryBlockFlags:=[];

 if RequiresDedicatedAllocation or PrefersDedicatedAllocation then begin
  Include(MemoryBlockFlags,TpvVulkanDeviceMemoryBlockFlag.DedicatedAllocation);
 end;

 fMemoryBlock:=pvApplication.VulkanDevice.MemoryManager.AllocateMemoryBlock(MemoryBlockFlags,
                                                                            MemoryRequirements.size,
                                                                            MemoryRequirements.alignment,
                                                                            MemoryRequirements.memoryTypeBits,
                                                                            TVkMemoryPropertyFlags(VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT),
                                                                            0,
                                                                            0,
                                                                            0,
                                                                            0,
                                                                            0,
                                                                            TpvVulkanDeviceMemoryAllocationType.ImageOptimal,
                                                                            @fVulkanImage.Handle);
 if not assigned(fMemoryBlock) then begin
  raise EpvVulkanMemoryAllocationException.Create('Memory for texture couldn''t be allocated!');
 end;

 fMemoryBlock.AssociatedObject:=self;

 VulkanCheckResult(pvApplication.VulkanDevice.Commands.BindImageMemory(pvApplication.VulkanDevice.Handle,
                                                                       fVulkanImage.Handle,
                                                                       fMemoryBlock.MemoryChunk.Handle,
                                                                       fMemoryBlock.Offset));

 Queue:=pvApplication.VulkanDevice.GraphicsQueue;

 CommandPool:=TpvVulkanCommandPool.Create(pvApplication.VulkanDevice,
                                          pvApplication.VulkanDevice.GraphicsQueueFamilyIndex,
                                          TVkCommandPoolCreateFlags(VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT));
 try

  CommandBuffer:=TpvVulkanCommandBuffer.Create(CommandPool,VK_COMMAND_BUFFER_LEVEL_PRIMARY);
  try

   Fence:=TpvVulkanFence.Create(pvApplication.VulkanDevice);
   try

    FillChar(ImageSubresourceRange,SizeOf(TVkImageSubresourceRange),#0);
    ImageSubresourceRange.aspectMask:=TVkImageAspectFlags(VK_IMAGE_ASPECT_COLOR_BIT);
    ImageSubresourceRange.baseMipLevel:=0;
    ImageSubresourceRange.levelCount:=MipMaps;
    ImageSubresourceRange.baseArrayLayer:=0;
    ImageSubresourceRange.layerCount:=6;
    fVulkanImage.SetLayout(TVkImageAspectFlags(VK_IMAGE_ASPECT_COLOR_BIT),
                           TVkImageLayout(VK_IMAGE_LAYOUT_UNDEFINED),
                           TVkImageLayout(VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL),
                           @ImageSubresourceRange,
                           CommandBuffer,
                           Queue,
                           Fence,
                           true);

    fVulkanSampler:=TpvVulkanSampler.Create(pvApplication.VulkanDevice,
                                            TVkFilter(VK_FILTER_LINEAR),
                                            TVkFilter(VK_FILTER_LINEAR),
                                            TVkSamplerMipmapMode(VK_SAMPLER_MIPMAP_MODE_LINEAR),
                                            TVkSamplerAddressMode(VK_SAMPLER_ADDRESS_MODE_REPEAT),
                                            TVkSamplerAddressMode(VK_SAMPLER_ADDRESS_MODE_REPEAT),
                                            TVkSamplerAddressMode(VK_SAMPLER_ADDRESS_MODE_REPEAT),
                                            0.0,
                                            false,
                                            1.0,
                                            false,
                                            TVkCompareOp(VK_COMPARE_OP_NEVER),
                                            0.0,
                                            MipMaps,
                                            TVkBorderColor(VK_BORDER_COLOR_FLOAT_OPAQUE_BLACK),
                                            false);

    fVulkanImageView:=TpvVulkanImageView.Create(pvApplication.VulkanDevice,
                                                fVulkanImage,
                                                TVkImageViewType(VK_IMAGE_VIEW_TYPE_CUBE),
                                                ImageFormat,
                                                TVkComponentSwizzle(VK_COMPONENT_SWIZZLE_IDENTITY),
                                                TVkComponentSwizzle(VK_COMPONENT_SWIZZLE_IDENTITY),
                                                TVkComponentSwizzle(VK_COMPONENT_SWIZZLE_IDENTITY),
                                                TVkComponentSwizzle(VK_COMPONENT_SWIZZLE_IDENTITY),
                                                TVkImageAspectFlags(VK_IMAGE_ASPECT_COLOR_BIT),
                                                0,
                                                MipMaps,
                                                0,
                                                6);

    fDescriptorImageInfo:=TVkDescriptorImageInfo.Create(fVulkanSampler.Handle,
                                                        fVulkanImageView.Handle,
                                                        VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL);

    ImageView:=TpvVulkanImageView.Create(pvApplication.VulkanDevice,
                                         fVulkanImage,
                                         TVkImageViewType(VK_IMAGE_VIEW_TYPE_CUBE),
                                         ImageFormat,
                                         TVkComponentSwizzle(VK_COMPONENT_SWIZZLE_IDENTITY),
                                         TVkComponentSwizzle(VK_COMPONENT_SWIZZLE_IDENTITY),
                                         TVkComponentSwizzle(VK_COMPONENT_SWIZZLE_IDENTITY),
                                         TVkComponentSwizzle(VK_COMPONENT_SWIZZLE_IDENTITY),
                                         TVkImageAspectFlags(VK_IMAGE_ASPECT_COLOR_BIT),
                                         0,
                                         1,
                                         0,
                                         6);
    try

     RenderPass:=TpvVulkanRenderPass.Create(pvApplication.VulkanDevice);
     try

       RenderPass.AddSubpassDescription(0,
                                        VK_PIPELINE_BIND_POINT_GRAPHICS,
                                        [],
                                        [RenderPass.AddAttachmentReference(RenderPass.AddAttachmentDescription(0,
                                                                                                               ImageFormat,
                                                                                                               VK_SAMPLE_COUNT_1_BIT,
                                                                                                               VK_ATTACHMENT_LOAD_OP_CLEAR,
                                                                                                               VK_ATTACHMENT_STORE_OP_STORE,
                                                                                                               VK_ATTACHMENT_LOAD_OP_DONT_CARE,
                                                                                                               VK_ATTACHMENT_STORE_OP_DONT_CARE,
                                                                                                               VK_IMAGE_LAYOUT_UNDEFINED,
                                                                                                               VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL
                                                                                                              ),
                                                                            VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL
                                                                           )],
                                        [],
                                        TpvInt32(VK_ATTACHMENT_UNUSED),
                                        []
                                       );
      RenderPass.AddSubpassDependency(VK_SUBPASS_EXTERNAL,
                                      0,
                                      TVkPipelineStageFlags(VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT),
                                      TVkPipelineStageFlags(VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT),
                                      TVkAccessFlags(VK_ACCESS_MEMORY_READ_BIT),
                                      TVkAccessFlags(VK_ACCESS_COLOR_ATTACHMENT_READ_BIT) or TVkAccessFlags(VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT),
                                      TVkDependencyFlags(VK_DEPENDENCY_BY_REGION_BIT));
      RenderPass.AddSubpassDependency(0,
                                      VK_SUBPASS_EXTERNAL,
                                      TVkPipelineStageFlags(VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT),
                                      TVkPipelineStageFlags(VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT),
                                      TVkAccessFlags(VK_ACCESS_COLOR_ATTACHMENT_READ_BIT) or TVkAccessFlags(VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT),
                                      TVkAccessFlags(VK_ACCESS_MEMORY_READ_BIT),
                                      TVkDependencyFlags(VK_DEPENDENCY_BY_REGION_BIT));
      RenderPass.Initialize;

      RenderPass.ClearValues[0].color.float32[0]:=0.0;
      RenderPass.ClearValues[0].color.float32[1]:=0.0;
      RenderPass.ClearValues[0].color.float32[2]:=0.0;
      RenderPass.ClearValues[0].color.float32[3]:=0.0;

      FrameBufferColorAttachment:=TpvVulkanFrameBufferAttachment.Create(pvApplication.VulkanDevice,
                                                                        fVulkanImage,
                                                                        ImageView,
                                                                        Width,
                                                                        Height,
                                                                        ImageFormat,
                                                                        false);
      try

       FrameBuffer:=TpvVulkanFrameBuffer.Create(pvApplication.VulkanDevice,
                                                RenderPass,
                                                Width,
                                                Height,
                                                6,
                                                [FrameBufferColorAttachment],
                                                false);
       try

        PipelineLayout:=TpvVulkanPipelineLayout.Create(pvApplication.VulkanDevice);
        try
         PipelineLayout.AddPushConstantRange(TVkPipelineStageFlags(VK_SHADER_STAGE_FRAGMENT_BIT),0,SizeOf(TpvVector4));
         PipelineLayout.Initialize;

         Pipeline:=TpvVulkanGraphicsPipeline.Create(pvApplication.VulkanDevice,
                                                    pvApplication.VulkanPipelineCache,
                                                    0,
                                                    [],
                                                    PipelineLayout,
                                                    RenderPass,
                                                    0,
                                                    nil,
                                                    0);
         try

          Pipeline.AddStage(fVulkanPipelineShaderStageVertex);
          Pipeline.AddStage(fVulkanPipelineShaderStageFragment);

          Pipeline.InputAssemblyState.Topology:=TVkPrimitiveTopology(VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST);
          Pipeline.InputAssemblyState.PrimitiveRestartEnable:=false;

          Pipeline.ViewPortState.AddViewPort(0.0,0.0,Width,Height,0.0,1.0);
          Pipeline.ViewPortState.AddScissor(0,0,Width,Height);

          Pipeline.RasterizationState.DepthClampEnable:=false;
          Pipeline.RasterizationState.RasterizerDiscardEnable:=false;
          Pipeline.RasterizationState.PolygonMode:=VK_POLYGON_MODE_FILL;
          Pipeline.RasterizationState.CullMode:=TVkCullModeFlags(VK_CULL_MODE_NONE);
          Pipeline.RasterizationState.FrontFace:=VK_FRONT_FACE_CLOCKWISE;
          Pipeline.RasterizationState.DepthBiasEnable:=false;
          Pipeline.RasterizationState.DepthBiasConstantFactor:=0.0;
          Pipeline.RasterizationState.DepthBiasClamp:=0.0;
          Pipeline.RasterizationState.DepthBiasSlopeFactor:=0.0;
          Pipeline.RasterizationState.LineWidth:=1.0;

          Pipeline.MultisampleState.RasterizationSamples:=VK_SAMPLE_COUNT_1_BIT;
          Pipeline.MultisampleState.SampleShadingEnable:=false;
          Pipeline.MultisampleState.MinSampleShading:=0.0;
          Pipeline.MultisampleState.CountSampleMasks:=0;
          Pipeline.MultisampleState.AlphaToCoverageEnable:=false;
          Pipeline.MultisampleState.AlphaToOneEnable:=false;

          Pipeline.ColorBlendState.LogicOpEnable:=false;
          Pipeline.ColorBlendState.LogicOp:=VK_LOGIC_OP_COPY;
          Pipeline.ColorBlendState.BlendConstants[0]:=0.0;
          Pipeline.ColorBlendState.BlendConstants[1]:=0.0;
          Pipeline.ColorBlendState.BlendConstants[2]:=0.0;
          Pipeline.ColorBlendState.BlendConstants[3]:=0.0;
          Pipeline.ColorBlendState.AddColorBlendAttachmentState(false,
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

          Pipeline.DepthStencilState.DepthTestEnable:=false;
          Pipeline.DepthStencilState.DepthWriteEnable:=false;
          Pipeline.DepthStencilState.DepthCompareOp:=VK_COMPARE_OP_ALWAYS;
          Pipeline.DepthStencilState.DepthBoundsTestEnable:=false;
          Pipeline.DepthStencilState.StencilTestEnable:=false;

          Pipeline.Initialize;

          Pipeline.FreeMemory;

          CommandBuffer.Reset(TVkCommandBufferResetFlags(VK_COMMAND_BUFFER_RESET_RELEASE_RESOURCES_BIT));

          CommandBuffer.BeginRecording(TVkCommandBufferUsageFlags(VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT));

          RenderPass.BeginRenderPass(CommandBuffer,FrameBuffer,VK_SUBPASS_CONTENTS_INLINE,0,0,Width,Height);

          CommandBuffer.CmdBindPipeline(VK_PIPELINE_BIND_POINT_GRAPHICS,Pipeline.Handle);

          CommandBuffer.CmdPushConstants(PipelineLayout.Handle,
                                         TVkShaderStageFlags(TVkShaderStageFlagBits.VK_SHADER_STAGE_FRAGMENT_BIT),
                                         0,
                                         SizeOf(TpvVector4),
                                         @LightDirection);

          CommandBuffer.CmdDraw(18,1,0,0);

          RenderPass.EndRenderPass(CommandBuffer);

          CommandBuffer.EndRecording;

          CommandBuffer.Execute(Queue,TVkPipelineStageFlags(VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT),nil,nil,Fence,true);

         finally
          FreeAndNil(Pipeline);
         end;

        finally
         FreeAndNil(PipelineLayout);
        end;

       finally
        FreeAndNil(FrameBuffer);
       end;

      finally
       FreeAndNil(FrameBufferColorAttachment);
      end;

     finally
      FreeAndNil(RenderPass);
     end;

    finally
     FreeAndNil(ImageView);
    end;

    // Generate mipmaps
    begin

     fVulkanImage.SetLayout(TVkImageAspectFlags(VK_IMAGE_ASPECT_COLOR_BIT),
                            TVkImageLayout(VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL),
                            TVkImageLayout(VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL),
                            @ImageSubresourceRange,
                            CommandBuffer,
                            Queue,
                            Fence,
                            true);

     ImageMemoryBarrier:=TVkImageMemoryBarrier.Create(0,
                                                      0,
                                                      VK_IMAGE_LAYOUT_UNDEFINED,
                                                      VK_IMAGE_LAYOUT_UNDEFINED,
                                                      TVkQueue(VK_QUEUE_FAMILY_IGNORED),
                                                      TVkQueue(VK_QUEUE_FAMILY_IGNORED),
                                                      fVulkanImage.Handle,
                                                      ImageSubresourceRange);

     CommandBuffer.Reset(TVkCommandBufferResetFlags(VK_COMMAND_BUFFER_RESET_RELEASE_RESOURCES_BIT));
     CommandBuffer.BeginRecording(TVkCommandBufferUsageFlags(VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT));
     for Index:=1 to MipMaps-1 do begin

      ImageMemoryBarrier.subresourceRange.levelCount:=1;
      ImageMemoryBarrier.subresourceRange.baseMipLevel:=Index-1;
      ImageMemoryBarrier.oldLayout:=VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL;
      ImageMemoryBarrier.newLayout:=VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL;
      ImageMemoryBarrier.srcAccessMask:=TVkAccessFlags(VK_ACCESS_TRANSFER_WRITE_BIT);
      ImageMemoryBarrier.dstAccessMask:=TVkAccessFlags(VK_ACCESS_TRANSFER_READ_BIT);
      CommandBuffer.CmdPipelineBarrier(TVkPipelineStageFlags(VK_PIPELINE_STAGE_TRANSFER_BIT),
                                        TVkPipelineStageFlags(VK_PIPELINE_STAGE_TRANSFER_BIT),
                                        0,
                                        0,
                                        nil,
                                        0,
                                        nil,
                                        1,
                                        @ImageMemoryBarrier);

      for FaceIndex:=0 to 5 do begin
       ImageBlit:=TVkImageBlit.Create(TVkImageSubresourceLayers.Create(TVkImageAspectFlags(VK_IMAGE_ASPECT_COLOR_BIT),
                                                                       Index-1,
                                                                       FaceIndex,
                                                                       1),
                                      [TVkOffset3D.Create(0,
                                                          0,
                                                          0),
                                       TVkOffset3D.Create(Width shr (Index-1),
                                                          Height shr (Index-1),
                                                          1)],
                                      TVkImageSubresourceLayers.Create(TVkImageAspectFlags(VK_IMAGE_ASPECT_COLOR_BIT),
                                                                       Index,
                                                                       FaceIndex,
                                                                       1),
                                      [TVkOffset3D.Create(0,
                                                          0,
                                                          0),
                                       TVkOffset3D.Create(Width shr Index,
                                                          Height shr Index,
                                                          1)]
                                     );

       CommandBuffer.CmdBlitImage(fVulkanImage.Handle,VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,
                                  fVulkanImage.Handle,VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
                                  1,
                                  @ImageBlit,
                                  TVkFilter(VK_FILTER_LINEAR));
      end;

      ImageMemoryBarrier.oldLayout:=VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL;
      ImageMemoryBarrier.newLayout:=VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL;
      ImageMemoryBarrier.srcAccessMask:=TVkAccessFlags(VK_ACCESS_TRANSFER_READ_BIT);
      ImageMemoryBarrier.dstAccessMask:=TVkAccessFlags(VK_ACCESS_SHADER_READ_BIT);
      CommandBuffer.CmdPipelineBarrier(TVkPipelineStageFlags(VK_PIPELINE_STAGE_TRANSFER_BIT),
                                       TVkPipelineStageFlags(VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT),
                                       0,
                                       0,
                                       nil,
                                       0,
                                       nil,
                                       1,
                                       @ImageMemoryBarrier);

     end;
     ImageMemoryBarrier.subresourceRange.baseMipLevel:=MipMaps-1;
     ImageMemoryBarrier.oldLayout:=VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL;
     ImageMemoryBarrier.newLayout:=VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL;
     ImageMemoryBarrier.srcAccessMask:=TVkAccessFlags(VK_ACCESS_TRANSFER_WRITE_BIT);
     ImageMemoryBarrier.dstAccessMask:=TVkAccessFlags(VK_ACCESS_SHADER_READ_BIT);
     CommandBuffer.CmdPipelineBarrier(TVkPipelineStageFlags(VK_PIPELINE_STAGE_TRANSFER_BIT),
                                      TVkPipelineStageFlags(VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT),
                                      0,
                                      0,
                                      nil,
                                      0,
                                      nil,
                                      1,
                                      @ImageMemoryBarrier);
     CommandBuffer.EndRecording;
     CommandBuffer.Execute(Queue,TVkPipelineStageFlags(VK_PIPELINE_STAGE_TRANSFER_BIT),nil,nil,Fence,true);

    end;

   finally
    FreeAndNil(Fence);
   end;

  finally
   FreeAndNil(CommandBuffer);
  end;

 finally
  FreeAndNil(CommandPool);
 end;

end;

destructor TSkyCubeMap.Destroy;
begin
 FreeAndNil(fMemoryBlock);
 FreeAndNil(fVulkanImageView);
 FreeAndNil(fVulkanSampler);
 FreeAndNil(fVulkanImage);
 FreeAndNil(fVulkanPipelineShaderStageVertex);
 FreeAndNil(fVulkanPipelineShaderStageFragment);
 FreeAndNil(fVertexShaderModule);
 FreeAndNil(fFragmentShaderModule);
 inherited Destroy;
end;

end.