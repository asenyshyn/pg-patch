#!/bin/bash

tools/sh/list-dependencies-from-patches.sh patches/*.sql | tsort
