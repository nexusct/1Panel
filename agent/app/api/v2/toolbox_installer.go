package v2

import (
	"errors"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"runtime"
	"strings"

	"github.com/1Panel-dev/1Panel/agent/app/api/v2/helper"
	"github.com/1Panel-dev/1Panel/agent/app/dto"
	"github.com/gin-gonic/gin"
)

// validToolKey matches only lowercase alphanumeric characters and hyphens.
var validToolKey = regexp.MustCompile(`^[a-z0-9-]+$`)

// scriptMap maps tool keys to their ci/ script filenames.
var installerScriptMap = map[string]string{
	"claude-code":  "install_ai_tools.sh",
	"codex-cli":    "install_ai_tools.sh",
	"odoo":         "install_odoo.sh",
	"shopify":      "install_shopify.sh",
	"contentful":   "install_contentful.sh",
	"strapi":       "install_strapi.sh",
	"react-bricks": "install_react_bricks.sh",
}

// installerCheckCmd maps tool keys to commands that check if the tool is installed.
var installerCheckCmd = map[string][]string{
	"claude-code":  {"claude", "--version"},
	"codex-cli":    {"codex", "--version"},
	"odoo":         {"docker", "inspect", "--format={{.State.Status}}", "odoo"},
	"shopify":      {"shopify", "version"},
	"contentful":   {"contentful", "--version"},
	"strapi":       {"node", "-e", "require('@strapi/strapi')"},
	"react-bricks": {"node", "-e", "require('react-bricks')"},
}

// getCIDir returns the absolute path to the ci/ directory relative to the binary.
func getCIDir() string {
	exe, err := os.Executable()
	if err != nil {
		return "/opt/1panel/ci"
	}
	return filepath.Join(filepath.Dir(exe), "ci")
}

// InstallTool runs the installer script for the requested tool and returns combined stdout/stderr.
// POST /api/v2/toolbox/installer/install
func (b *BaseApi) InstallTool(c *gin.Context) {
	var req dto.InstallerToolReq
	if err := helper.CheckBindAndValidate(&req, c); err != nil {
		return
	}

	if !validToolKey.MatchString(req.Tool) {
		helper.BadRequest(c, errors.New("invalid tool key"))
		return
	}

	scriptFile, ok := installerScriptMap[req.Tool]
	if !ok {
		helper.BadRequest(c, errors.New("unknown tool: "+req.Tool))
		return
	}

	if runtime.GOOS == "windows" {
		helper.BadRequest(c, errors.New("toolbox installers require Linux/macOS"))
		return
	}

	ciDir := getCIDir()
	scriptPath := filepath.Join(ciDir, scriptFile)

	if _, err := os.Stat(scriptPath); os.IsNotExist(err) {
		helper.BadRequest(c, errors.New("installer script not found at "+scriptPath))
		return
	}

	cmd := exec.CommandContext(c.Request.Context(), "bash", scriptPath)
	cmd.Env = append(os.Environ(), "INSTALL_TOOL="+req.Tool)

	out, err := cmd.CombinedOutput()
	res := dto.InstallerToolRes{Output: strings.TrimSpace(string(out))}
	if err != nil {
		res.Error = err.Error()
		helper.SuccessWithData(c, res)
		return
	}
	helper.SuccessWithData(c, res)
}

// GetToolInstallStatus checks whether a tool's binary / container is present.
// GET /api/v2/toolbox/installer/status/:tool
func (b *BaseApi) GetToolInstallStatus(c *gin.Context) {
	tool := c.Param("tool")

	if !validToolKey.MatchString(tool) {
		helper.BadRequest(c, errors.New("invalid tool key"))
		return
	}

	args, ok := installerCheckCmd[tool]
	if !ok {
		helper.BadRequest(c, errors.New("unknown tool: "+tool))
		return
	}

	out, err := exec.Command(args[0], args[1:]...).CombinedOutput() //nolint:gosec
	if err != nil {
		helper.SuccessWithData(c, dto.InstallerToolStatus{Installed: false})
		return
	}
	helper.SuccessWithData(c, dto.InstallerToolStatus{
		Installed: true,
		Version:   strings.TrimSpace(string(out)),
	})
}
