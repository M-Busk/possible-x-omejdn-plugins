#  Copyright 2024 Dataport. All rights reserved. Developed as part of the MERLOT project.
#  Copyright 2024-2025 Dataport. All rights reserved. Extended as part of the POSSIBLE project.
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.

FROM ghcr.io/fraunhofer-aisec/omejdn-server:1.7.1


RUN apt update \
    && apt install -y python3-pip jq \
    && apt-get clean \
    && pip3 install yq

WORKDIR /opt

COPY . .

EXPOSE 4567

CMD [ "ruby", "omejdn.rb" ]