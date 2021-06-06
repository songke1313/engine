// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/compositor/renderer.h"

#include "flutter/fml/logging.h"
#include "impeller/compositor/command_buffer.h"
#include "impeller/compositor/surface.h"

namespace impeller {

constexpr size_t kMaxFramesInFlight = 3u;

Renderer::Renderer(std::string shaders_directory)
    : frames_in_flight_sema_(::dispatch_semaphore_create(kMaxFramesInFlight)),
      context_(std::make_shared<Context>(std::move(shaders_directory))) {
  if (!context_->IsValid()) {
    return;
  }

  is_valid_ = true;
}

Renderer::~Renderer() = default;

bool Renderer::IsValid() const {
  return is_valid_;
}

bool Renderer::Render(const Surface& surface) {
  if (!IsValid()) {
    return false;
  }

  if (!surface.IsValid()) {
    return false;
  }

  auto command_buffer = context_->CreateRenderCommandBuffer();

  if (!command_buffer) {
    return false;
  }

  ::dispatch_semaphore_wait(frames_in_flight_sema_, DISPATCH_TIME_FOREVER);

  command_buffer->Commit(
      [sema = frames_in_flight_sema_](CommandBuffer::CommitResult) {
        ::dispatch_semaphore_signal(sema);
      });
  return true;
}

std::shared_ptr<Context> Renderer::GetContext() const {
  return context_;
}

}  // namespace impeller