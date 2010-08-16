#!/bin/bash
x="$(ps a | grep ipclient | grep T)" ; kill -9 "${x%pts*}"
