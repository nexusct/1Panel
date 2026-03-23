package dto

type InstallerToolReq struct {
	Tool string `json:"tool" binding:"required"`
}

type InstallerToolRes struct {
	Output string `json:"output"`
	Error  string `json:"error,omitempty"`
}

type InstallerToolStatus struct {
	Installed bool   `json:"installed"`
	Version   string `json:"version,omitempty"`
}
