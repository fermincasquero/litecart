package queries

import (
	"context"
	"database/sql"
	"fmt"
	"time"

	"github.com/shurco/litecart/internal/models"
	"github.com/shurco/litecart/pkg/security"
)

type InstallQueries struct {
	*sql.DB
}

func (q *InstallQueries) Install(i *models.Install) error {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	tx, err := q.BeginTx(ctx, nil)
	if err != nil {
		return err
	}
	defer tx.Rollback()

	var installed bool
	q.DB.QueryRow(`SELECT "value" FROM "setting" WHERE "key" = ?`, "installed").Scan(&installed)
	if installed {
		return fmt.Errorf("%s", "Rejected because you have already installed and configured the cart")
	}

	stmt, err := tx.PrepareContext(ctx, `UPDATE "setting" SET "value" = ? WHERE "key" = ?`)
	if err != nil {
		return err
	}
	defer stmt.Close()

	password := security.GeneratePassword(i.Password)
	jwt_secret, err := security.NewToken(password)
	if err != nil {
		return err
	}

	settings := map[string]string{
		"installed":         "true",
		"domain":            i.Domain,
		"email":             i.Email,
		"password":          security.GeneratePassword(i.Password),
		"jwt_secret":        jwt_secret,
		"stripe_secret_key": i.StripeSecret,
	}

	for key, value := range settings {
		if _, err := stmt.ExecContext(ctx, value, key); err != nil {
			return err
		}
	}

	if err := tx.Commit(); err != nil {
		return err
	}

	return nil
}