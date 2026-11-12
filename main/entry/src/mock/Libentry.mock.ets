/*
* Copyright (C) 2026 Huawei Device Co., Ltd.
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
* http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/

// Previewer 不能运行 AudioSuite，明确拒绝，禁止伪造算法成功。
const NativeMock: Record<string, Object> = {
  'run': async (): Promise<void> => {
    throw new Error('Previewer 不支持 AudioSuite，请连接鸿蒙设备运行');
  }
};
export default NativeMock;
