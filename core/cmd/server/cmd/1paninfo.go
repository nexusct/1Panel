package cmd

import (
	"fmt"
	"strings"

	"github.com/1Panel-dev/1Panel/core/cmd/server/conf"
	"github.com/1Panel-dev/1Panel/core/constant"
	"github.com/1Panel-dev/1Panel/core/global"
	"github.com/1Panel-dev/1Panel/core/i18n"
	"gopkg.in/yaml.v3"

	"github.com/spf13/cobra"
)

func init() {
	RootCmd.AddCommand(paninfoCmd)
}

var paninfoCmd = &cobra.Command{
	Use:   "1paninfo",
	Short: "Show 1Panel status information",
	RunE: func(cmd *cobra.Command, args []string) error {
		i18n.UseI18nForCmd(language)
		if !isRoot() {
			fmt.Println(i18n.GetMsgWithMapForCmd("SudoHelper", map[string]interface{}{"cmd": "sudo 1pctl 1paninfo"}))
			return nil
		}
		db, err := loadDBConn("core.db")
		if err != nil {
			return err
		}
		agentDB, err := loadDBConn("agent.db")
		if err != nil {
			return err
		}

		version := getSettingByKey(db, "SystemVersion")
		mode := ""
		config := global.ServerConfig{}
		if err := yaml.Unmarshal(conf.AppYaml, &config); err == nil {
			mode = config.Base.Mode
		}

		port := getSettingByKey(db, "ServerPort")
		ssl := getSettingByKey(db, "SSL")
		entrance := getSettingByKey(db, "SecurityEntrance")
		mfa := getSettingByKey(db, "MFAStatus")
		allowIPs := getSettingByKey(db, "AllowIPs")
		domain := getSettingByKey(db, "BindDomain")
		ipv6 := getSettingByKey(db, "Ipv6")
		address := getSettingByKey(agentDB, "SystemIP")
		user := getSettingByKey(db, "UserName")

		protocol := "http"
		if ssl == constant.StatusEnable {
			protocol = "https"
		}
		displayAddress := address
		if len(domain) != 0 {
			displayAddress = domain
		}
		if displayAddress == "" {
			displayAddress = "$LOCAL_IP"
		}

		panelURL := fmt.Sprintf("%s://%s:%s/%s", protocol, displayAddress, port, entrance)

		listenMode := "IPv4"
		if ipv6 == constant.StatusEnable {
			listenMode = "IPv6"
		}

		enabled := i18n.GetMsgByKeyForCmd("PanelInfoEnabled")
		disabled := i18n.GetMsgByKeyForCmd("PanelInfoDisabled")
		notSet := i18n.GetMsgByKeyForCmd("PanelInfoNotSet")

		separator := strings.Repeat("=", 55)
		divider := strings.Repeat("-", 55)

		fmt.Println(separator)
		fmt.Println(" " + i18n.GetMsgByKeyForCmd("PanelInfoTitle"))
		fmt.Println(separator)
		fmt.Printf(" %-24s%s\n", i18n.GetMsgByKeyForCmd("SystemVersion"), version)
		fmt.Printf(" %-24s%s\n", i18n.GetMsgByKeyForCmd("SystemMode"), mode)
		fmt.Println(divider)
		fmt.Printf(" %-24s%s\n", i18n.GetMsgByKeyForCmd("UserInfoAddr"), panelURL)
		fmt.Printf(" %-24s%s\n", i18n.GetMsgByKeyForCmd("PanelInfoUsername"), user)
		fmt.Println(divider)

		sslStatus := disabled
		if ssl == constant.StatusEnable {
			sslStatus = enabled
		}
		mfaStatus := disabled
		if mfa == constant.StatusEnable {
			mfaStatus = enabled
		}
		entranceStatus := disabled
		if entrance != "" {
			entranceStatus = enabled + " (/" + entrance + ")"
		}
		allowIPsStatus := disabled
		if allowIPs != "" {
			allowIPsStatus = enabled
		}
		domainStatus := notSet
		if domain != "" {
			domainStatus = domain
		}

		fmt.Printf(" %-24s%s\n", i18n.GetMsgByKeyForCmd("PanelInfoSSL"), sslStatus)
		fmt.Printf(" %-24s%s\n", i18n.GetMsgByKeyForCmd("PanelInfoMFA"), mfaStatus)
		fmt.Printf(" %-24s%s\n", i18n.GetMsgByKeyForCmd("PanelInfoEntrance"), entranceStatus)
		fmt.Printf(" %-24s%s\n", i18n.GetMsgByKeyForCmd("PanelInfoAllowIPs"), allowIPsStatus)
		fmt.Printf(" %-24s%s\n", i18n.GetMsgByKeyForCmd("PanelInfoDomain"), domainStatus)
		fmt.Printf(" %-24s%s\n", i18n.GetMsgByKeyForCmd("PanelInfoListenMode"), listenMode)
		fmt.Println(separator)

		return nil
	},
}
