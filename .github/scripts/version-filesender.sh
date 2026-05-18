#!/bin/bash
set -euo pipefail

DOCKERFILE="$1"

FS_VERSION=$(grep 'ARG FILESENDER_VERSION=' "$DOCKERFILE" | head -n1 | cut -d'=' -f2 | tr -d '" ')
PHP_IMAGE=$(grep '^FROM php:' "$DOCKERFILE" | head -n1 | awk '{print $2}')
PHP_VERSION=$(echo "$PHP_IMAGE" | cut -d':' -f2 | cut -d'-' -f1)

echo "version=${FS_VERSION}"
echo "image_tag=${FS_VERSION}-php${PHP_VERSION}"
echo "chart_base_version=$(echo "$FS_VERSION" | cut -d'.' -f1-2)"
echo "description_suffix=FileSender v${FS_VERSION}"
